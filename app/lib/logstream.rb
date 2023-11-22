require "redis"

class Logstream
  attr_accessor :url

  def initialize(url)
    uri = URI.parse(url)
    @url = "#{uri.scheme}://#{uri.user}:#{uri.password}@#{uri.host}:#{uri.port}"
    @redis = Redis.new(url: @url)
    @stream_key = uri.path.sub("/", "")
  end

  def info(message)
    append(message + "\n")
  end

  def error(message)
    append("\e[31m#{message}\n\e[0m")
  end

  def success(message)
    append("\e[32m#{message}\n\e[0m")
  end

  def append(message)
    raise "Logstream is terminated" if terminated?
    @redis.xadd(@stream_key, {event_type: "log", bytes: message})
  end

  def read
    result = ""

    @redis.xrange(@stream_key, "-", "+").map do |entry|
      case entry.fetch(1).fetch("event_type")
      when "log"
        result << entry.fetch(1).fetch("bytes")
      when "disconnect"
        return result
      else
        raise "Unknown event type #{entry.fetch(1).fetch("event_type")}"
      end
    end

    result
  end

  def terminate!
    @redis.xadd(@stream_key, {event_type: "disconnect"})
  end

  def terminated?
    return false if !@redis.exists(@stream_key)

    stream_entries = @redis.xrange(@stream_key, "-", "+")

    return false if stream_entries.empty?

    stream_entries.last.fetch(1).fetch("event_type") == "disconnect"
  end
end
