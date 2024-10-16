class TestRunnerOutput
  attr_accessor :test_script_result

  def initialize(test_script_result)
    @test_script_result = test_script_result
  end

  def compilation_failed?
    last_stage_logs.nil? # Assume that compilation failed if there are no stage logs
  end

  def failed_stage
    stage_position = last_stage_logs_without_colors.match(/^\[stage-(\d+)\]/)[1].to_i
    Store.instance.models_for(CourseStage).find { |stage| stage.course_id == course.id && stage.position == stage_position }
  end

  def last_stage_logs
    blocks = test_script_result.stdout.split("\n\n")

    # This finds the last block that starts with a stage identifier (it first removes ASCII color codes)
    blocks.reverse.find { |block| block.gsub(/\e\[(\d+)m/, "").start_with?("[tester::") }
  end

  def last_stage_logs_without_colors
    last_stage_logs.gsub(/\e\[(\d+)m/, "")
  end

  def passed?
    !compilation_failed? && last_stage_logs.gsub(/\e\[(\d+)m/, "").include?("Test passed.")
  end

  def raw_output
    test_script_result.stdout + test_script_result.stderr
  end
end
