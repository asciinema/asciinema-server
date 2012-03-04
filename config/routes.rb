AsciiIo::Application.routes.draw do

  resources :asciicasts
  match ':id' => 'asciicasts#show', :constraints => { :id => /\d+/ }

  namespace :api do
    resources :asciicasts do

      resources :comments

    end
  end

  match "/auth/:provider/callback" => "sessions#create"
  match "/auth/failure" => "sessions#failure"

  match "/login" => "sessions#new"
  match "/logout" => "sessions#destroy"

  root :to => 'asciicasts#index'
end
