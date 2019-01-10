Rails.application.routes.draw do
  root 'pages#index'
  resources :tito_webhooks do
    post 'registration_completed', on: :collection
  end
end
