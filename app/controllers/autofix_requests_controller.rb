class AutofixRequestsController < ApplicationController
  def create
    autofix_request = AutofixRequest.create!(
      codecrafters_server_url: params[:codecrafters_server_url],
      course_slug: params[:course_slug],
      course_stage_slug: params[:course_stage_slug],
      id: params[:id],
      language_slug: params[:language_slug],
      logstream_url: params[:logstream_url],
      last_successful_submission_commit_sha: params[:last_successful_submission_commit_sha],
      repository_clone_url: params[:repository_clone_url],
      submission_commit_sha: params[:submission_commit_sha]
    )

    ProcessAutofixRequestJob.perform_later(autofix_request)

    render json: {id: autofix_request.id, status: autofix_request.status}
  end
end
