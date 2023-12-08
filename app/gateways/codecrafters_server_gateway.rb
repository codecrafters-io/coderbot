class CodecraftersServerGateway
  def create_test_run(codecrafters_server_url:, autofix_request_id:, commit_sha:, stage_slugs:)
    response = HTTParty.post(
      "#{codecrafters_server_url}/services/autofix/create_test_run",
      body: {
        autofix_request_id: autofix_request_id,
        commit_sha: commit_sha,
        stage_slugs: stage_slugs
      }.to_json,
      headers: {"Content-Type" => "application/json"}
    )

    unless response.code.eql?(200)
      raise "Failed to create test run. Status code: #{response.code}, body: #{response.body}"
    end

    {
      id: response.fetch("id"),
      logstream_url: response.fetch("logstream_url")
    }
  end

  def fetch_test_run(codecrafters_server_url:, test_run_id:)
    response = HTTParty.get("#{codecrafters_server_url}/services/autofix/fetch_test_run?test_run_id=#{test_run_id}")

    unless response.code.eql?(200)
      raise "Failed to fetch test run. Status code: #{response.code}, body: #{response.body}"
    end

    {
      status: response.fetch("status")
    }
  end
end
