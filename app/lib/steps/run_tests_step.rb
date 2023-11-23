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
    self.test_runner_output = LocalTestRunner.new(stage.course, local_repository.repository_dir).run_tests(stage)

    logstream.append("\n")
    logstream.append(test_runner_output.raw_output)
    logstream.append("\n\n")

    if ENV["DEBUG"].eql?("true")
      puts ""
      puts test_runner_output.raw_output
      puts ""
    end

    if test_runner_output.passed?
      success!
      logstream.success("Tests passed!")
    else
      failure!
      logstream.error("Tests failed!")
    end
  end
end
