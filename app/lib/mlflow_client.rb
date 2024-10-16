class MlflowClient
  BASE_URL = "https://dbc-79c30a15-a36b.cloud.databricks.com"

  def create_run(tags)
    response = HTTParty.post("#{BASE_URL}/api/2.0/mlflow/runs/create", {
      headers: headers,
      body: {
        experiment_id: 4270847108618290,
        start_time: Time.now.to_i * 1000,
        tags: tags.map { |k, v| {key: k, value: v} }
      }.to_json
    })

    if response.code != 200
      raise "Failed to create MLflow run: #{response.body}"
    end

    {
      id: JSON.parse(response.body).fetch("run").fetch("info").fetch("run_id"),
      artifact_uri: JSON.parse(response.body).fetch("run").fetch("info").fetch("artifact_uri")
    }
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
  def log_test_dataset(run_id, name, digest, profile, source_type, source, schema)
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

  def upload_artifact(local_path, artifact_uri, artifact_path)
    absolute_dbfs_path = "#{artifact_uri.sub("dbfs:", "").sub(/^\/databricks/, "")}/#{artifact_path}"

    HTTParty.post("#{BASE_URL}/api/2.0/dbfs/put", {
      headers: headers,
      body: {
        path: absolute_dbfs_path,
        contents: File.open(local_path)
      }
    })
  end

  protected

  def headers
    {
      "Authorization" => "Bearer #{ENV["MLFLOW_API_KEY"]}"
    }
  end
end
