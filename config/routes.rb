AsciiIo::Application.routes.draw do

  resources :asciicasts, :path => 'a'

  match "/~:nickname" => "users#show", :as => :profile

  match "/browse" => "asciicasts#index", :as => :browse

  match "/manual" => "static_pages#show", :page => 'manual'

  match "/auth/:provider/callback" => "sessions#create"
  match "/auth/failure" => "sessions#failure"

  match "/login" => "sessions#new"
  match "/logout" => "sessions#destroy"

  match "/connect/:user_token" => "user_tokens#create"

  resource :users, :only => [:create]

  namespace :api do
    resources :comments

    resources :asciicasts do
      resources :comments
    end
  end

  root :to => 'home#show'
end
