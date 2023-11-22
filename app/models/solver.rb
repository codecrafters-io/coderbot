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

  def with_cloned_repository(&block)
    repository_dir = Dir.mktmpdir
    ShellCommand.run!("git clone #{repository_clone_url} #{repository_dir}")
    block.call(LocalRepository.new(repository_dir))
  ensure
    # On Github actions, using Dir.mktmpdir { |dir| ... } causes a permissions error for some reason
    `rm -rf #{repository_dir}` if repository_dir
  end

  def course
    Course.find_by_slug!(course_slug)
  end

  def course_stage
    course.stages.detect { |stage| stage.slug == course_stage_slug } || raise(ActiveRecord::RecordNotFound)
  end

  def language
    Language.find_by_slug!(language_slug)
  end

  def logstream
    Logstream.new(logstream_url)
  end
end
