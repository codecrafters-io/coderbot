class MlflowClient
  BASE_URL = "https://dbc-79c30a15-a36b.cloud.databricks.com"

  def create_run(tags)
    HTTParty.post("#{BASE_URL}/api/2.0/mlflow/runs/create", {
      headers: headers,
      body: {
        experiment_id: 4270847108618290,
        start_time: Time.now.to_i * 1000,
        tags: tags.map { |k, v| {key: k, value: v} }
      }.to_json
    })
  end

  def delete_run(run_id)
    HTTParty.post("#{BASE_URL}/api/2.0/mlflow/runs/delete", {
      headers: headers,
      body: {run_id: run_id}.to_json
    })
  end

  def log_metric(run_id, step, key, value)
    HTTParty.post("#{BASE_URL}/api/2.0/mlflow/runs/log-metric", {
      headers: headers,
      body: {
        run_id: run_id,
        key: key,
        value: value,
        timestamp: Time.now.to_i * 1000,
        step: step
      }.to_json
    })
  end

  def log_param(run_id, key, value)
    HTTParty.post("#{BASE_URL}/api/2.0/mlflow/runs/log-parameter", {
      headers: headers,
      body: {
        run_id: run_id,
        key: key,
        value: value
      }.to_json
    })
  end

  # Example: MlflowClient.new.log_test_dataset("<wip>", "test", "test", "internal", "codecrafters", "zip", "7 entries")
  def log_test_dataset(run_id, name, digest, source_type, source, schema, profile)
    HTTParty.post("#{BASE_URL}/api/2.0/mlflow/runs/log-inputs", {
      headers: headers,
      body: {
        run_id: run_id,
        datasets: [
          {
            tags: [{key: "context", value: "text"}],
            dataset: {
              name: name,
              digest: digest,
              source_type: source_type,
              source: source,
              schema: schema,
              profile: profile
            }
          }
        ]
      }.to_json
    })
  end

  def update_run(run_id, status)
    HTTParty.post("#{BASE_URL}/api/2.0/mlflow/runs/update", {
      headers: headers,
      body: {
        run_id: run_id,
        status: status,
        end_time: Time.now.to_i * 1000
      }.to_json
    })
  end

  protected

  def headers
    {
      "Authorization" => "Bearer #{ENV["MLFLOW_API_KEY"]}"
    }
  end
end
