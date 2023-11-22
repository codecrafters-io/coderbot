class Steps::RunTestsStep < Steps::BaseStep
  attr_accessor :local_repository
  attr_accessor :stage

  attr_accessor :test_runner_output

  def initialize(stage:, local_repository:, **args)
    super(**args)

    @stage = stage
    @local_repository = local_repository
  end

  def perform
    self.test_runner_output = LocalTestRunner.new(stage.course, local_repository.repository_dir).run_tests(stage)
  end

  def success?
    test_runner_output.passed?
  end

  def title
    "Run tests (Stage ##{stage.position})"
  end
end
