Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  
  devise_for :users

  resources :metadata_types, except: [:new, :show] do
    collection do
      get :search
      get :list
    end
    scope module: 'metadata_types' do
      resources :metadata, except: [:index, :new, :show] do
        collection do
          get :search
        end
      end
    end
  end
  resources :contents do
    collection do
      get :search
    end
  end
  resources :copyright_permissions,  except: [:index]
  resources :organizations, except: [:index, :show]
  get 'copyright/index'

  get 'home/about'
  root 'home#index'
end
