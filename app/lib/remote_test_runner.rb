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
      ShellCommand.run!("git commit -m 'Autofix [skip ci]'")
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
      buffered_logstream_writer.write(chunk)
    end

    buffered_logstream_writer.flush

    # TODO: Find a way to not rely on exit code?
    TestRunnerOutput.new(ShellCommandResult.new(exit_code: 0, stdout: test_run_logstream.read_available, stderr: ""))
  end
end
