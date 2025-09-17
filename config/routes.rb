Rails.application.routes.draw do
  devise_for :users
  root "pages#home"

  resources :properties do
    member do
      post :favorite
      delete :unfavorite
    end
  end

  resources :listings do
    resources :bookings, shallow: true do
      member do
        patch :confirm
        patch :cancel
      end
    end
  end

  resources :favorites, only: [ :index ]
  resources :profiles, only: [ :show, :edit, :update ]

  # Messaging routes
  resources :conversations do
    resources :messages, shallow: true
  end

  # Contact page
  get "contact", to: "contact#index"
  post "contact", to: "contact#create"

  # About page
  get "about", to: "about#index"

  # Webhook routes
  namespace :webhooks do
    resources :stripe, only: [ :create ]
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
