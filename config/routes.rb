Rails.application.routes.draw do

  get '/a/:id.js' => redirect(ActionController::Base.helpers.asset_path("widget.js"), status: 302)

  resources :asciicasts, path: 'a' do
    member do
      get '/raw' => 'asciicasts#embed' # legacy route, probably no longer used anywhere
      get :embed
      get :example
    end
  end

  get "/u/:id" => "users#show", as: :unnamed_user
  get "/~:username" => "users#show", as: :public_profile

  get "/oembed" => "oembed#show", as: :oembed

  resource :username do
    get :skip
  end

  root 'home#show'
end
