class Solver < ApplicationRecord
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
