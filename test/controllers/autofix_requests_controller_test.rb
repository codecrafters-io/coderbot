require "test_helper"

class AutofixRequestsControllerTest < ActionDispatch::IntegrationTest
  test "can create & fetch autofix_requests" do
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

    get "/autofix_requests/#{AutofixRequest.first.id}"

    assert_response :success
    assert_equal "not_started", JSON.parse(response.body)["status"]

    perform_enqueued_jobs

    get "/autofix_requests/#{AutofixRequest.first.id}"

    assert_response :success
    assert_equal "error", JSON.parse(response.body)["status"]
  end
end
