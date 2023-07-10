Rails.application.routes.draw do
  resources :authentication do
    collection do
      post :login
      post :logout
    end
  end
end
