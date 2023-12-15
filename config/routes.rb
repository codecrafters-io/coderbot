require "resque/server"

Rails.application.routes.draw do
  root "site#index"

  resources :autofix_requests, only: [:create, :show]

  mount Resque::Server.new, at: "/admin/resque"
end
