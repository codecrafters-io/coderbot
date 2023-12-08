class RemoteTestRunner
  def initialize(codecrafters_server_url, repository_dir)
    @codecrafters_server_url = codecrafters_server_url
    @repository_dir = repository_dir
  end

  def run_tests(autofix_request_id, stage, logstream: nil, stream_output: false)
    stages_to_test = stage.previous_stages + [stage]
    branch_name = "autofix-#{(Time.now.to_f * 1000).round}"

    commit_sha = Dir.chdir(@repository_dir) do
      ShellCommand.run!("git checkout -b #{branch_name}")
      ShellCommand.run!("git add .")
      ShellCommand.run!("git commit --allow-empty -m 'Autofix [skip ci]'")
      ShellCommand.run!("git push origin #{branch_name}")
      ShellCommand.run!("git rev-parse HEAD").stdout.strip
    end

    test_run = CodecraftersServerGateway.new.create_test_run(
      codecrafters_server_url: @codecrafters_server_url,
      autofix_request_id: autofix_request_id,
      commit_sha: commit_sha,
      stage_slugs: stages_to_test.map(&:slug)
    )

    test_run_logstream = Logstream.new(test_run.fetch(:logstream_url))
    buffered_logstream_writer = BufferedWriter.new(logstream)

    test_run_logstream.each_chunk do |chunk|
      $stdout.write(chunk) if stream_output
      buffered_logstream_writer.write(chunk)
    end

    buffered_logstream_writer.flush

    test_run_status = CodecraftersServerGateway.new.fetch_test_run(
      codecrafters_server_url: @codecrafters_server_url,
      test_run_id: test_run.fetch(:id)
    )

    raise "Unexpected test run status: pending" if test_run_status.fetch(:status).eql?("pending") # TODO: Failsafe, handle this properly

    # TODO: Find a way to not rely on exit code?
    TestRunnerOutput.new(ShellCommandResult.new(0, test_run_logstream.read_available, ""))
  end
end
