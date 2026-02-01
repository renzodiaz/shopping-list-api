Rails.application.routes.draw do
  use_doorkeeper

  devise_for :users, skip: [ :sessions, :registrations ]

  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
