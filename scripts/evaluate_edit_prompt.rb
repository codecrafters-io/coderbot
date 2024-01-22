samples = Dir.glob("data/edit_samples/*").map do |sample_dir|
  {
    original: File.read("#{sample_dir}/original.rb"),
    edited: File.read("#{sample_dir}/edited.rb"),
    instructions: File.read("#{sample_dir}/instructions.md")
  }
end
