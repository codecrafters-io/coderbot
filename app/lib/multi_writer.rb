# Helper class to write to multiple targets at once
class MultiWriter
  def initialize(*targets)
    @targets = targets
  end

  def write(*)
    @targets.map { |t| t.write(*) }.first
  end

  def close
    @targets.each(&:close)
  end
end
