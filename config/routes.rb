Rails.application.routes.draw do
  root "articles#index"

  resources :articles, only: [:index, :new, :create, :show] do
    post :retry, on: :member
    get :stream, on: :member
  end

  resources :conversations, only: [:index, :new, :create, :show, :destroy] do
    resources :messages, only: [:create]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
