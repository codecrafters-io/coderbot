class EventLogger
  class << self
    def debug(event_name, event_properties = {})
      log("DEBUG", event_name, event_properties)
    end

    def info(event_name, event_properties = {})
      log("INFO", event_name, event_properties)
    end

    def with_context(new_contextual_event_properties)
      old_contextual_event_properties = contextual_event_properties
      Thread.current[:contextual_event_properties] = contextual_event_properties.merge(new_contextual_event_properties)

      yield
    ensure
      Thread.current[:contextual_event_properties] = old_contextual_event_properties
    end

    private

    def add_sentry_breadcrumb(event_name, level, data)
      Sentry.add_breadcrumb(
        Sentry::Breadcrumb.new(
          category: event_name.split(".").first,
          message: event_name.split(".").last,
          level:,
          data:
        )
      )
    end

    def contextual_event_properties
      Thread.current[:contextual_event_properties] ||= {}
      Thread.current[:contextual_event_properties]
    end

    def default_event_properties
      {
        **(Current.user ? {user_id: Current.user.id, username: Current.user.username} : {}),
        **(Current.session&.country ? {session_country: Current.session.country.code} : {}),
        **(Current.session&.impersonator ? {impersonator_username: Current.session.impersonator.username} : {})
      }
    end

    def log(level, event_name, event_properties = {})
      message = event_properties.delete(:message)

      merged_properties = {
        **default_event_properties,
        **contextual_event_properties,
        **event_properties
      }

      event = LogStash::Event.new({
        **merged_properties,
        **(message ? {message: message} : {}),
        event: event_name,
        level: level
      })

      event["message"] = if message
        "[#{event_name}] #{message}"
      else
        "[#{event_name}] #{merged_properties.map { |k, v| "#{k}=\"#{v.to_s.gsub('"', '\"')}\"" }.join(" ")}"
      end

      if Rails.env.production?
        puts event.to_json
      else
        puts event["message"]
      end
    end
  end
end
