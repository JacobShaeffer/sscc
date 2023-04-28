Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  
  devise_for :users

  resources :metadata_types do
    resources :metadata, except: [:index, :show], controller: 'metadata_types/metadata'
  end
  resources :contents
  resources :copyright_permissions,  except: [:index]
  resources :organizations, except: [:index, :show]
  get 'copyright/index'

  get 'home/about'
  root 'home#index'
end
