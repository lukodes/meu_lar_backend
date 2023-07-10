Rails.application.routes.draw do
  resources :login do
    collection do
      post :login
      post :logout
    end
  end
end
