autofix_request = AutofixRequest.order(created_at: :desc).first

ENV["DEBUG"] = "true"

puts "cloning repository..."

autofix_request.with_cloned_repository do |local_repository|
  puts "cloned repository!"

  Steps::RunTestsStep.new(
    autofix_request: autofix_request,
    workflow: OpenStruct.new(log_prefix: ""),
    stage: autofix_request.course_stage,
    local_repository: local_repository,
    logstream: autofix_request.logstream
  ).run!
end
