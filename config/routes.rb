Rails.application.routes.draw do
  use_doorkeeper

  devise_for :users, skip: [ :sessions, :registrations ]

  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/confirm", to: "auth#confirm"
      post "auth/resend_confirmation", to: "auth#resend_confirmation"

      resources :categories, only: %i[index show]
      resources :unit_types, only: %i[index show]
      resources :items, only: %i[index show create update destroy]

      resources :households, only: %i[index show create update destroy] do
        resources :members, only: %i[index destroy], controller: "households/members"
        post "leave", to: "households/members#leave"
        resources :invitations, only: %i[index create destroy], controller: "households/invitations"
      end

      resources :invitations, only: %i[show], param: :token do
        member do
          post :accept
          post :decline
        end
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
