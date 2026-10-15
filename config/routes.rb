Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication routes
  get  '/login',  to: 'sessions#new',     as: :login
  post '/login',  to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy', as: :logout

  get  '/register', to: 'registrations#new', as: :register
  post '/register', to: 'registrations#create'

  # Admin panel routes
  get  '/admin',           to: 'admin#index',       as: :admin
  post '/admin/bulk_action', to: 'admin#bulk_action', as: :admin_bulk_action

  # Chat routes (for parts 2 and 3)
  get  '/chat',   to: 'chat#index', as: :chat
  post '/chat',   to: 'chat#create'

  # Root path redirects to admin panel (or login if not authenticated)
  root to: redirect('/admin')
end