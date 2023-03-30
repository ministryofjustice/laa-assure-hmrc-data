Rails.application.routes.draw do
  devise_for :users,
    controllers: {
      omniauth_callbacks: 'users/omniauth_callbacks'
    }

  devise_scope :user do
    unauthenticated :user do
      root 'pages#landing', as: :unauthenticated_root
    end

    authenticated :user do
      root to: 'bulk_submissions#index', as: :authenticated_root
    end

    get 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  resources :users, only: :show
  resources :bulk_submissions, only: [:index, :new, :create, :edit, :update, :destroy]
  resources :bulk_submission_forms, only: [:new, :create, :edit, :update, :destroy]

  get "ping", to: "status#ping", format: :json
  get "healthcheck", to: "status#status", format: :json
  get "status", to: "status#ping", format: :json

  scope via: :all do
    get "/404", to: "errors#not_found"
    get "/422", to: "errors#unprocessable_entity"
    get "/429", to: "errors#too_many_requests"
    get "/500", to: "errors#internal_server_error"
  end
end
