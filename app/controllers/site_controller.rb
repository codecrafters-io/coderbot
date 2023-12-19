class SiteController < ApplicationController
  def index
    render plain: "Hello, world!"
  end

  def test_error
    TestErrorJob.perform_later
    raise "Boom from web!"
  end
end
