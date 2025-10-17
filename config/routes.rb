# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :loaded_questions do
    resources :games, only: %i[create new show] do
      member do
        get :new_round
        get :players
        patch :completed_round
        patch :guessing_round
        patch :swap_guesses
      end
      resource :player, only: %i[create new edit update] do
        member do
          patch :answer
        end
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
