original_code = File.read("scripts/debug/test_file_for_edit.rb").strip

stats = []

3.times do |i|
  puts "Editing attempt ##{i + 1}"

  edited_code = Experimental::EditCodePromptV2.call!(
    original_code: original_code,
    edit_instructions_markdown: <<~MARKDOWN,
      - Remove the `protected` keyword above the `ensure_flush_thread_is_running!` method.
    MARKDOWN
    logstream: $stdout
  ).result

  puts edited_code
  exit

  diff = Diffy::Diff.new(original_code, edited_code, context: 3)
  added_lines = diff.each.select { |line| line.match(/^\+/) }
  removed_lines = diff.each.select { |line| line.match(/^-/) }

  puts ""
  puts "Diff (+#{added_lines.size} lines, -#{removed_lines.size} lines):"
  puts ""

  puts Diffy::Diff.new(original_code, edited_code, context: 0).to_s(:color)
  puts ""

  stats << {
    diff: diff.to_s(:color),
    added_lines_count: added_lines.size,
    removed_lines_count: removed_lines.size
  }
end

puts "Stats:"
puts "Added lines: #{stats.map { |s| s[:added_lines_count] }.inspect}"
puts "Removed lines: #{stats.map { |s| s[:removed_lines_count] }.inspect}"
