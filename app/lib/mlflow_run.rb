class MlflowRun
  BASE_URL = "https://dbc-79c30a15-a36b.cloud.databricks.com"

  attr_accessor :run_id

  def initialize(run_id:)
    @run_id = run_id
  end

  def self.create!
    run_id = MlflowClient.create_run({environment: ENV["CI"] ? "ci" : "local"})
    MlflowRun.new(run_id: run_id)
  end

  def log_dataset(name:, profile:, digest: "unknown", source_type: "internal", source: "codecrafters", schema: "zip")
    MlflowClient.new.log_test_dataset(run_id, name, digest, profile, source_type, source, schema)
  end

  def log_metric(step, key, value)
    MlflowClient.new.log_metric(run_id, step, key, value)
  end
end
