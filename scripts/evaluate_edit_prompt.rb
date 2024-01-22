class EditTrainingSample
  attr_accessor :original_file_path
  attr_accessor :edited_file_path
  attr_accessor :edit_instructions_markdown
  attr_accessor :slug
  attr_accessor :filename

  def initialize(original_file_path:, edited_file_path:, edit_instructions_markdown:, slug:, filename:)
    @original_file_path = original_file_path
    @edited_file_path = edited_file_path
    @edit_instructions_markdown = edit_instructions_markdown
    @slug = slug
    @filename = filename
  end
end

class TripleSlashFixer
  def self.fix(code)
    if code.ends_with?("```")
      [true, code.match(/```\w*\n(.*)```/m)[1].strip]
    else
      [false, code]
    end
  end
end

class CodeTagFixer
  def self.fix(code)
    if code.ends_with?("</code>")
      [true, code.match(/<code>\n(.*)<\/code>/m)[1].strip]
    else
      [false, code]
    end
  end
end

samples = Dir.glob("data/edit_samples/*").map do |sample_dir|
  files = Dir.glob("#{sample_dir}/*")
  original_file_path = files.grep(/\.original\./).first
  edited_file_path = files.grep(/\.edited\./).first

  original_filename = File.basename(original_file_path).gsub(".original.", ".")
  edited_filename = File.basename(edited_file_path).gsub(".edited.", ".")

  if original_filename != edited_filename
    raise "Original and edited files must have the same name, but got #{original_filename} and #{edited_filename}"
  end

  EditTrainingSample.new(
    original_file_path: original_file_path,
    edited_file_path: edited_file_path,
    edit_instructions_markdown: File.read("#{sample_dir}/instructions.md"),
    slug: File.basename(sample_dir),
    filename: original_filename
  )
end

fixer_usages = []
fixers = [TripleSlashFixer, CodeTagFixer]

puts "Found #{samples.size} samples"

results = samples.pmap(8) do |sample|
  puts "Evaluating #{sample.slug}"
  actual_edited_code = Experimental::EditCodePrompt.call!(original_code: File.read(sample.original_file_path), edit_instructions_markdown: sample.edit_instructions_markdown).result
  actual_edited_code = actual_edited_code.strip
  expected_edited_code = File.read(sample.edited_file_path).strip

  fixers.each do |fixer|
    next if actual_edited_code.eql?(expected_edited_code)

    fixer_used, fixed_edited_code = fixer.fix(actual_edited_code)

    if fixer_used
      actual_edited_code = fixed_edited_code
      fixer_usages << fixer
    end
  end

  if actual_edited_code != expected_edited_code
    puts ""
    puts "Sample #{sample.slug} failed"
    puts "Diff:"
    puts ""
    puts Diffy::Diff.new(expected_edited_code, actual_edited_code, context: 5).to_s(:color)
    puts ""
    puts "---"
    puts ""
  end

  puts "- #{sample.slug}: #{(actual_edited_code == expected_edited_code) ? "PASS" : "FAIL"}"
  [sample.slug, actual_edited_code == expected_edited_code]
end.to_h

puts results
puts ""
puts results.values.tally
puts fixer_usages.map(&:to_s).tally
