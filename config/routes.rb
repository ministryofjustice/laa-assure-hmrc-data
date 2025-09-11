require "sidekiq/web"

# Configure Sidekiq-specific session middleware
Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use Rails.application.config.session_store, Rails.application.config.session_options

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"

  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    # Protect against timing attacks:
    # - See https://codahale.com/a-lesson-in-timing-attacks/
    # - See https://thisdata.com/blog/timing-attacks-against-string-comparison/
    # - Use & (do not use &&) so that it doesn't short circuit.
    # - Use digests to stop length information leaking
    secure_compare(username, ENV.fetch('SIDEKIQ_WEB_UI_USERNAME', nil)) & secure_compare(password, ENV.fetch('SIDEKIQ_WEB_UI_PASSWORD', nil))
  end

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

    if Rails.configuration.x.mock_azure
      get 'sign_in', to: 'users/mock_azure#new', as: :new_user_session
      post 'sign_in', to: 'users/mock_azure#create', as: :user_session
    end
    get 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  resources :users, only: :show
  resources :bulk_submissions, only: [:show, :index, :destroy] do
    if Rails.env.local? || Rails.host.uat?
      get :process_all, on: :collection
    end
    get :download, on: :member
  end
  resources :bulk_submission_forms, only: [:new, :create, :edit, :update, :destroy]

  get "ping", to: "status#ping", format: :json
  get "healthcheck", to: "status#status", format: :json
  get "status", to: "status#ping", format: :json

  scope via: :all do
    get "/404", to: "errors#not_found"
    get "/422", to: "errors#unprocessable_content"
    get "/429", to: "errors#too_many_requests"
    get "/500", to: "errors#internal_server_error"
    get "/out-of-hours", to: "errors#out_of_hours"
  end
end

def secure_compare(passed, stored)
  Rack::Utils.secure_compare(Digest::SHA256.hexdigest(passed), Digest::SHA256.hexdigest(stored))
end
