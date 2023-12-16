Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.environment = ENV["SENTRY_ENV"]
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Set traces_sample_rate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production.
  # config.traces_sample_rate = 1.0

  config.traces_sampler = lambda do |sampling_context|
    # if this is the continuation of a trace, just use that decision (rate controlled by the caller)
    unless sampling_context[:parent_sampled].nil?
      next sampling_context[:parent_sampled]
    end

    rack_env = sampling_context[:env]
    transaction_context = sampling_context[:transaction_context]
    op = transaction_context[:op]
    transaction_name = transaction_context[:name]
    http_method = rack_env ? rack_env["REQUEST_METHOD"] : "n/a"

    case op
    when /resque/
      0.1
    when /websocket/
      0.1
    when /http/
      if transaction_name.eql?("/") && http_method.eql?("GET")
        0 # ignore / requests
      else
        1 # If we haven't decided to sample by now, let it through!
      end
    else
      1 # Let all other requests through, add more clauses if needed
    end
  end
end
