class Steps::RunTestsStep < Steps::BaseStep
  attr_accessor :local_repository
  attr_accessor :stage
  attr_accessor :logstream

  attr_accessor :test_runner_output

  def initialize(stage:, local_repository:, logstream:, **args)
    super(**args)

    @stage = stage
    @local_repository = local_repository
    @logstream = logstream
  end

  def do_run!
    logstream.info("Running tests...")
    logstream.append("\n")
    $stdout.write("\n") if is_debug?

    self.test_runner_output = LocalTestRunner.new(stage.course, local_repository.repository_dir).run_tests(stage, stream_output: is_debug?, logstream: logstream)

    logstream.append("\n")
    $stdout.write("\n") if is_debug?

    if test_runner_output.passed?
      success!
      logstream.success("Tests passed!")
    else
      failure!
      logstream.error("Tests failed!")
    end

    logstream.append("\n")
  end

  def is_debug?
    ENV["DEBUG"].eql?("true")
  end
end
