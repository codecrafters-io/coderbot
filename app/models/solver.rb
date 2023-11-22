class Solver < ApplicationRecord
  # t.string :status, null: false
  # t.string :repository_clone_url, null: false
  # t.string :last_submission_commit_sha, null: false
  # t.string :last_successful_submission_commit_sha
  # t.string :language_slug, null: false
  # t.string :course_slug, null: false
  # t.string :course_stage_slug, null: false
  # t.string :logstream_url, null: false

  ALL_STATUSES = %w[not_started started failure success error].freeze

  enum status: ALL_STATUSES.zip(ALL_STATUSES).to_h

  validates_presence_of :repository_clone_url
  validates_presence_of :last_submission_commit_sha
  validates_presence_of :language_slug
  validates_presence_of :course_slug
  validates_presence_of :course_stage_slug
  validates_presence_of :logstream_url

  before_validation do
    self.status ||= "not_started"
  end
end
