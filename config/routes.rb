AsciiIo::Application.routes.draw do
  resources :asciicasts
  match ':id' => 'asciicasts#show', :constraints => { :id => /\d+/ }

  namespace :api do
    resources :asciicasts
  end

  match "/auth/:provider/callback" => "sessions#create"
  match "/auth/failure" => "sessions#failure"

  match "/logout" => "sessions#destroy"

  root :to => 'asciicasts#index'
end
