class AddModels < ActiveRecord::Migration[7.0]
  def change
    enable_extension "pgcrypto"

    create_table :solvers, id: :uuid do |t|
      t.string :status, null: false
      t.string :repository_clone_url, null: false
      t.string :last_submission_commit_sha, null: false
      t.string :last_successful_submission_commit_sha
      t.string :language_slug, null: false
      t.string :course_slug, null: false
      t.string :course_stage_slug, null: false
      t.string :logstream_url, null: false
      t.timestamps
    end
  end
end
