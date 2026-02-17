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

      resources :notifications, only: %i[index show] do
        member do
          post :mark_as_read
        end
        collection do
          post :mark_all_as_read
          get :unread_count
        end
      end

      resources :device_tokens, only: %i[index create destroy]

      resources :households, only: %i[index show create update destroy] do
        resources :members, only: %i[index destroy], controller: "households/members"
        post "leave", to: "households/members#leave"
        resources :invitations, only: %i[index create destroy], controller: "households/invitations"
        resources :shopping_lists, only: %i[index show create update destroy], controller: "households/shopping_lists" do
          member do
            post :complete
            post :duplicate
          end
        end
        resources :inventory, only: %i[index show create update destroy], controller: "households/inventory_items" do
          member do
            post :adjust
          end
        end
      end

      resources :shopping_lists, only: [] do
        resources :items, only: %i[index create update destroy], controller: "shopping_list_items" do
          member do
            post :check
            post :uncheck
            post :not_in_stock
          end
        end
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
