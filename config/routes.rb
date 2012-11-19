AsciiIo::Application.routes.draw do

  match "/browse" => "asciicasts#index", :as => :browse
  match "/browse/popular" => "asciicasts#popular", :as => :popular

  resources :asciicasts, :path => 'a' do
    member do
      get :raw
    end
  end

  match "/~:nickname" => "users#show", :as => :profile

  match "/docs" => "docs#show", :page => 'record'
  match "/docs/:page" => "docs#show", :as => :docs

  match "/auth/:provider/callback" => "sessions#create"
  match "/auth/failure" => "sessions#failure"

  match "/login" => "sessions#new"
  match "/logout" => "sessions#destroy"

  match "/connect/:user_token" => "user_tokens#create"

  resource :user, :only => [:create, :edit, :update]

  namespace :api do
    resources :comments

    resources :asciicasts do
      resources :comments
    end
  end

  root :to => 'home#show'

  match '*a', :to => 'application#not_found'
end
