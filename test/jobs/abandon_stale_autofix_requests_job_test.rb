require "test_helper"

class AbandonStaleAutofixRequestsJobTest < ActiveJob::TestCase
  test "should abandon stale autofix requests" do
    autofix_request = AutofixRequest.create!(
      created_at: 6.minutes.ago,
      codecrafters_server_url: "https://dummy_url.com",
      course_slug: "redis",
      course_stage_slug: "ping-pong",
      id: SecureRandom.uuid,
      language_slug: "ruby",
      logstream_url: "redis://localhost:6911/#{SecureRandom.uuid}",
      last_successful_submission_commit_sha: "1234567890abcdef",
      repository_clone_url: "file:///tmp/codecrafters/redis/bind-to-a-port/code",
      submission_commit_sha: "1234567890abcdef"
    )

    assert_difference("AutofixRequest.not_finalized.count", -1) do
      AbandonStaleAutofixRequestsJob.perform_now
    end

    autofix_request.reload
    assert_equal "error", autofix_request.status
    assert_equal "This autofix request was cancelled because it took more than 5 minutes to run. If this looks like a bug, please contact us at hello@codecrafters.io", autofix_request.explanation_markdown
  end
end
