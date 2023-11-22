class LocalTestRunner
  attr_accessor :course
  attr_accessor :repository_dir

  def initialize(course, repository_dir)
    @course = course
    @repository_dir = repository_dir
  end

  def run_tests(stage)
    buildpack = course.buildpacks.detect { |buildpack| buildpack.slug == language_pack } || raise("No buildpack found for #{language_pack}")

    Tempfile.create do |tmpfile|
      tmpfile.write(buildpack.dockerfile_contents)
      tmpfile.close

      dockerfile_path = tmpfile.path

      build_command = ShellCommand.new("docker build -t #{docker_image_tag}  -f #{dockerfile_path} #{@repository_dir}")
      build_command.run!

      tester_dir = TesterDownloader.new(course).download_if_needed

      course_stages = Store.instance.models_for(CourseStage).select { |stage| stage.course_id == course.id }
      stages_to_test = course_stages.select { |s| s.position <= stage.position }
      test_cases_json = stages_to_test.map(&:tester_test_case_json).to_json

      run_command = ShellCommand.new([
        "docker run",
        "--rm",
        "--cap-add SYS_ADMIN",
        "-v '#{File.expand_path(@repository_dir)}:/app'",
        "-v '#{File.expand_path(tester_dir)}:/tester:ro'",
        "-v '#{File.expand_path("fixtures/test.sh")}:/init.sh'",
        "-e CODECRAFTERS_SUBMISSION_DIR=/app",
        "-e CODECRAFTERS_TEST_CASES_JSON='#{test_cases_json}'",
        "-e CODECRAFTERS_CURRENT_STAGE_SLUG=#{stage.slug}", # TODO: Remove this
        "-e TESTER_DIR=/tester",
        "-w /app",
        "--memory=4g",
        "--cpus=2",
        "#{docker_image_tag} /init.sh"
      ].join(" "))

      run_command_result = run_command.run(stream_output: true, summarize: false)

      # Precompilation failures might cause the test runner to exit with a non-zero exit code.
      # raise "Failed to run tests, got exit code #{run_command_result.exit_code}. Stdout: #{run_command_result.stdout} Stderr: #{run_command_result.stderr}" unless [0, 1].include?(run_command_result.exit_code)

      TestRunnerOutput.new(run_command_result)
    end
  end

  protected

  def docker_image_tag
    "coderbot-#{course.slug}-#{language_pack}"
  end

  def language_pack
    YAML.load_file(File.join(repository_dir, "codecrafters.yml"))["language_pack"]
  end

  def tester_dir
    TesterDownloader.new(course).download_if_needed
  end
end
