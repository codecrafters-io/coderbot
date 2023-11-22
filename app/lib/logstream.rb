require "redis"

class Logstream
  attr_accessor :url

  def initialize(url)
    uri = URI.parse(url)
    @url = "#{uri.scheme}://#{uri.user}:#{uri.password}@#{uri.host}:#{uri.port}"
    @redis = Redis.new(url: @url)
    @stream_key = uri.path.sub("/", "")
    @terminated = false
  end

  def append(message)
    raise "Logstream is terminated" if terminated?
    @redis.rpush(@stream_key, message)
  end

  def read
    @redis.lrange(@stream_key, 0, -1).join(" ") unless terminated?
  end

  def terminate!
    @terminated = true
    @redis.del(@stream_key)
  end

  def terminated?
    @terminated
  end
end
