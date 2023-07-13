Rails.application.routes.draw do
  resources :authentication do
    collection do
      post :login
      post :logout
    end
  end

  resources :finder do
    collection do
      post :search_info
    end
  end
end
