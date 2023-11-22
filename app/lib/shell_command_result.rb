class ShellCommandResult
  attr_accessor :exit_code
  attr_accessor :stdout
  attr_accessor :stderr

  def initialize(exit_code, stdout, stderr)
    @exit_code = exit_code
    @stdout = stdout
    @stderr = stderr
  end

  def failure?
    !success?
  end

  def success?
    exit_code == 0
  end
end
