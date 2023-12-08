Rails.application.routes.draw do
  root "site#index"

  resources :autofix_requests, only: [:create, :show]
end
