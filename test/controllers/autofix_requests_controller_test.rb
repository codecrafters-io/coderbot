require "test_helper"

class AutofixRequestsControllerTest < ActionDispatch::IntegrationTest
  test "POST /autofix_requests should create request" do
    Store.ensure_loaded!

    post "/autofix_requests", params: {
      codecrafters_server_url: "https://dummy_url.com",
      course_slug: "redis",
      course_stage_slug: "ping-pong",
      id: SecureRandom.uuid,
      language_slug: "ruby",
      logstream_url: "redis://localhost:6911/#{SecureRandom.uuid}",
      last_successful_submission_commit_sha: "1234567890abcdef",
      repository_clone_url: "file:///tmp/codecrafters/redis/bind-to-a-port/code",
      submission_commit_sha: "1234567890abcdef"
    }

    assert_response :success
    assert_equal 1, AutofixRequest.count
  end
end
