require "resque/server"

Rails.application.routes.draw do
  root "site#index"

  get "/test_error", to: "site#test_error"

  resources :autofix_requests, only: [:create, :show]

  mount Resque::Server.new, at: "/admin/resque"
end
