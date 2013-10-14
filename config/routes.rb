Asciinema::Application.routes.draw do

  get "/browse" => "asciicasts#index", :as => :browse
  get "/browse/popular" => "asciicasts#popular", :as => :popular

  resources :asciicasts, :path => 'a' do
    member do
      get :raw
    end
  end

  get "/~:nickname" => "users#show", :as => :profile

  get "/docs" => "docs#show", :page => 'gettingstarted', :as => :docs_index
  get "/docs/:page" => "docs#show", :as => :docs

  get "/auth/:provider/callback" => "sessions#create"
  get "/auth/failure" => "sessions#failure"

  get "/login" => "sessions#new"
  get "/logout" => "sessions#destroy"

  get "/connect/:user_token" => "user_tokens#create"

  resource :user, :only => [:create, :edit, :update]

  namespace :api do
    resources :asciicasts
  end

  root 'home#show'

  mount JasmineRails::Engine => "/specs" unless Rails.env.production?

  get '/test/widget/:id' => 'test_widget#show' if Rails.env.test?

  match '*a', :via => [:get, :post], :to => 'application#not_found'
end
