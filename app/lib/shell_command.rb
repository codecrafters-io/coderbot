require "open3"

class ShellCommand
  attr_accessor :command

  def initialize(command)
    @command = command
  end

  # For mocking in tests
  def self.popen3(command)
    Open3.popen3(command)
  end

  def self.run!(command, **)
    new(command).run!(**)
  end

  def run(stream_output: false, summarize: false)
    summarize_writer = PrefixedLineWriter.new(ANSI.yellow("[shell_command] "), $stderr)
    summarize_writer.write "#{command}\n" if summarize

    start_time = Time.now

    _, stdout_io, stderr_io, wait_thr = ShellCommand.popen3(command)

    stdout_captured, stderr_captured = StringIO.new, StringIO.new

    io_threads = []

    if stream_output
      io_threads << Thread.new { setup_io_relay(stdout_io, $stdout, stdout_captured) }
      io_threads << Thread.new { setup_io_relay(stderr_io, $stderr, stderr_captured) }
    else
      io_threads << Thread.new { setup_io_relay(stdout_io, File.open(File::NULL, "w"), stdout_captured) }
      io_threads << Thread.new { setup_io_relay(stderr_io, File.open(File::NULL, "w"), stderr_captured) }
    end

    exit_code = wait_thr.value.exitstatus
    io_threads.each(&:join)
    stdout, stderr = stdout_captured.string, stderr_captured.string

    end_time = Time.now
    duration = end_time - start_time

    if summarize
      if exit_code.zero?
        summarize_writer.write("Success in #{duration.round(2)}s: #{command}\n")
      else
        summarize_writer.write("Failed in #{duration.round(2)}s with #{exit_code}: #{command}\n")
      end
    end

    ShellCommandResult.new(exit_code, stdout, stderr)
  end

  def run!(**)
    result = run(**)

    raise <<~ERROR if result.failure?
      Command failed: #{command}. Exit code: #{result.exit_code}

      STDOUT: #{result.stdout}

      STDERR: #{result.stderr}
    ERROR

    result
  end

  protected

  def setup_io_relay(source, prefixed_destination, other_destination)
    IO.copy_stream(
      source,
      MultiWriter.new(
        PrefixedLineWriter.new("     ", prefixed_destination),
        other_destination
      )
    )
  end
end
