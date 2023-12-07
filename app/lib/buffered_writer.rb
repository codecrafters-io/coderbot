# Helper class to write to multiple targets at once
class BufferedWriter
  def initialize(target)
    @target = target
    @buffer = []
    @is_flushing = false
  end

  def flush
    @is_flushing = true
    @flush_thread&.join
  end

  def write(*args)
    ensure_flush_thread_is_running!
    @buffer << args[0]
  end

  protected

  def ensure_flush_thread_is_running!
    @flush_thread ||= Thread.new do
      loop do
        if @buffer.any?
          to_write = @buffer.shift(100)
          @target.write(to_write.join(""))
        elsif @is_flushing
          # Nothing left in buffer, and we're flushing, so we're done
          break
        else
          sleep(0.1)
        end
      end
    end
  end
end
