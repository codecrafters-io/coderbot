require "redis"

class Logstream
  def initialize(url)
    split_url = url.rpartition("/")

    @redis_url = split_url.first
    @stream_key = split_url.last
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
    redis_client.xadd(@stream_key, {event_type: "log", bytes: message}, id: "*")
  end

  def each_chunk(chunk_timeout: 60.seconds, &block)
    last_seen_id = 0
    disconnect_event_seen = false

    loop do
      stream_to_entries_map = redis_client.xread(@stream_key, last_seen_id, block: chunk_timeout.in_milliseconds)
      stream_entries = stream_to_entries_map.fetch(@stream_key, [])

      if stream_entries.empty?
        raise Timeout::Error, "Timed out waiting for log data"
      end

      stream_entries.each do |entry|
        entry_id, entry_data = entry

        if entry_data["event_type"] == "log"
          block.call(entry_data["bytes"])
        elsif entry_data["event_type"] == "disconnect"
          disconnect_event_seen = true
        end

        last_seen_id = entry_id
      end

      break if disconnect_event_seen
    end
  end

  # Used in the API
  def id
    @stream_key
  end

  def read_available
    logstream_data = redis_client.xread(@stream_key, 0)

    return "" if logstream_data.length == 0

    event_string = logstream_data.values.first.map do |event|
      event[1]["bytes"] if event[1]["event_type"] == "log"
    end

    event_string.compact.join
  end

  # Returns [data, next_offset]
  # If the stream is terminated, next_offset will be nil
  def read_with_cursor(cursor)
    stream_to_entries_map = redis_client.xread(@stream_key, cursor || 0)
    stream_entries = stream_to_entries_map.fetch(@stream_key, [])

    # Either: (a) Stream is not created yet, we return 0 as the next cursor (b) No new data is available, we return the same cursor
    return ["", cursor || "0"] if stream_entries.length == 0

    content = ""
    last_seen_entry_id = cursor

    stream_entries.each do |entry|
      entry_id, entry_data = entry

      if entry_data["event_type"] == "log"
        content += entry_data["bytes"] if entry_data["event_type"] == "log"
        last_seen_entry_id = entry_id
      elsif entry_data["event_type"] == "disconnect"
        return [content, nil]
      else
        raise "Unknown event type: #{entry_data["event_type"]}"
      end
    end

    [content, last_seen_entry_id]
  end

  def terminate!
    redis_client.xadd(@stream_key, {event_type: "disconnect"})
  end

  def terminated?
    # This uses 100, just in case there are any "log" events after the "disconnect" event. This shouldn't happen, but it could!
    redis_client.xrevrange(@stream_key, "+", "-", count: 100).any? { |event| event[1]["event_type"] == "disconnect" }
  end

  def url
    "#{@redis_url}/#{@stream_key}"
  end

  protected

  def redis_client
    @redis_client ||= Redis.new(url: @redis_url)
  end
end
