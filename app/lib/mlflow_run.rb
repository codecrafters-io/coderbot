class MlflowRun
  BASE_URL = "https://dbc-79c30a15-a36b.cloud.databricks.com"

  attr_accessor :run_id
  attr_accessor :artifact_uri

  def initialize(run_id:, artifact_uri:)
    @run_id = run_id
    @artifact_uri = artifact_uri
  end

  def self.create!
    run = MlflowClient.new.create_run({environment: ENV["CI"] ? "ci" : "local"})
    MlflowRun.new(run_id: run.fetch(:id), artifact_uri: run.fetch(:artifact_uri))
  end

  def finish!
    MlflowClient.new.update_run(run_id, "FINISHED")
  end

  def log_dataset(name:, profile:, digest: "unknown", source_type: "internal", source: "codecrafters", schema: "zip")
    MlflowClient.new.log_test_dataset(run_id, name, digest, profile, source_type, source, schema)
  end

  def log_metric(step, key, value)
    MlflowClient.new.log_metric(run_id, step, key, value)
  end

  def log_param(key, value)
    MlflowClient.new.log_param(run_id, key, value)
  end
end
