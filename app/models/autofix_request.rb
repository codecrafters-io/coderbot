class AutofixRequest < ApplicationRecord
  ALL_STATUSES = %w[not_started in_progress failure success error].freeze

  enum status: ALL_STATUSES.zip(ALL_STATUSES).to_h

  validates_presence_of :repository_clone_url
  validates_presence_of :submission_commit_sha
  validates_presence_of :language_slug
  validates_presence_of :course_slug
  validates_presence_of :course_stage_slug
  validates_presence_of :logstream_url

  validates_presence_of :explanation_markdown, if: :finalized?

  validates_presence_of :duration_ms, if: :success?
  validates_presence_of :steps_count, if: :success?
  validates_presence_of :changed_files, if: :success?

  validates_presence_of :course
  validates_presence_of :course_stage

  before_validation do
    self.status ||= "not_started"
  end

  def changed_lines_count
    changed_files.map do |changed_file|
      changed_file["diff"].split("\n").count { |line| line.start_with?("+", "-") }
    end.sum
  end

  def course
    Course.find_by_slug!(course_slug)
  end

  def course_stage
    course.stages.detect { |stage| stage.slug == course_stage_slug } || raise(ActiveRecord::RecordNotFound)
  end

  def duration_secs
    (duration_ms.to_f / 1000.0).round(2)
  end

  def finalized?
    success? || failure? || error?
  end

  def friendly_id
    @friendly_id ||= FriendlyIdGenerator.generate(Integer(submission_commit_sha, 16))
  end

  def language
    Language.find_by_slug!(language_slug)
  end

  def logstream
    Logstream.new(logstream_url)
  end

  def with_cloned_repository(&block)
    repository_dir = Dir.mktmpdir
    ShellCommand.run!("git clone #{repository_clone_url} #{repository_dir}")
    block.call(LocalRepository.new(repository_dir))
  ensure
    # On Github actions, using Dir.mktmpdir { |dir| ... } causes a permissions error for some reason
    `rm -rf #{repository_dir} 2>&1 > /dev/null` if repository_dir
  end
end
