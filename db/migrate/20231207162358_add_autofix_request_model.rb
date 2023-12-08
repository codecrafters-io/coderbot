class AddAutofixRequestModel < ActiveRecord::Migration[7.0]
  def change
    rename_table :solvers, :autofix_requests
    add_column :autofix_requests, :codecrafters_server_url, :string
    rename_column :autofix_requests, :last_submission_commit_sha, :submission_commit_sha
  end
end
