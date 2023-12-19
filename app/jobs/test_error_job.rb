class TestErrorJob < ApplicationJob
  def perform
    raise "Boom from job!"
  end
end
