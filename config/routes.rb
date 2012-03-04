AsciiIo::Application.routes.draw do

  resources :asciicasts, :path => 'a'

  match '/~:nickname' => "users#show", :as => :profile

  match "/installation" => "static_pages#show", :page => 'installation'

  match "/auth/:provider/callback" => "sessions#create"
  match "/auth/failure" => "sessions#failure"

  match "/login" => "sessions#new"
  match "/logout" => "sessions#destroy"

  match "/connect/:user_token" => "user_tokens#create"

  namespace :api do
    resources :comments

    resources :asciicasts do
      resources :comments
    end
  end

  root :to => 'home#show'
end
