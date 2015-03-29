Rails.application.routes.draw do

  get "/browse" => "asciicasts#index", :as => :browse
  get "/browse/:category" => "asciicasts#index", :as => :category

  get '/a/:id.js' => redirect(ActionController::Base.helpers.asset_path("widget.js"), status: 302)

  resources :asciicasts, path: 'a' do
    member do
      get '/raw' => 'api/asciicasts#show'
      get :example
    end
  end

  get "/u/:id" => "users#show", as: :unnamed_user
  get "/~:username" => "users#show", as: :public_profile

  get "/oembed" => "oembed#show", as: :oembed

  namespace :api do
    resources :asciicasts
  end

  get "/docs" => "docs#show", :page => 'getting-started', :as => :docs_index
  get "/docs/:page" => "docs#show", :as => :docs

  resource :login, only: [:new, :create] do
    get :sent
  end

  get "/login" => redirect("/login/new")

  get "/login/:token" => "sessions#create", as: :login_token
  get "/logout" => "sessions#destroy"

  get "/connect/:api_token" => "api_tokens#create"

  resource :user

  resource :username do
    get :skip
  end

  root 'home#show'

  get '/about' => 'pages#show', page: :about, as: :about
  get '/privacy' => 'pages#show', page: :privacy, as: :privacy
  get '/tos' => 'pages#show', page: :tos, as: :tos
  get '/contributing' => 'pages#show', page: :contributing, as: :contributing

end
