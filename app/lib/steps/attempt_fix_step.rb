class Steps::AttemptFixStep < Steps::BaseStep
  attr_accessor :local_repository
  attr_accessor :stage
  attr_accessor :test_runner_output
  attr_accessor :logstream

  attr_accessor :diff
  attr_accessor :explanation

  def initialize(stage:, local_repository:, test_runner_output:, logstream:, **args)
    super(**args)

    @stage = stage
    @local_repository = local_repository
    @test_runner_output = test_runner_output
    @logstream = logstream
  end

  def do_run!
    current_code = File.read(local_repository.code_file_path)

    result = EditWrongSubmissionV1Prompt.call(
      stage: stage,
      language: local_repository.language,
      original_code: current_code,
      test_runner_output: test_runner_output
    ).result

    # There can be multiple code blocks, we want the one that's the longest
    edited_code_candidates = result.scan(/```#{local_repository.language.syntax_highlighting_identifier}\n(.*?)```/m).flatten
    edited_code = edited_code_candidates.max_by(&:length)

    # There can be text before and after the code block, that's the "explanation"
    self.explanation = result.gsub(/```#{local_repository.language.syntax_highlighting_identifier}\n(.*?)```/m, "")

    self.diff = Diffy::Diff.new(current_code, edited_code, context: 2)

    logstream.info("Explanation:")
    logstream.info("")
    logstream.info(explanation.presence || "No explanation provided.")
    logstream.info("")

    logstream.info("Diff:")
    logstream.info("")
    logstream.append(diff.to_s(:color))
    logstream.info("")

    if ENV["DEBUG"].eql?("true")
      puts "Diff:"
      puts ""
      puts diff.to_s(:color)
      puts ""
    end

    File.write(local_repository.code_file_path, edited_code)

    success!
  end
end
