Rails.application.routes.draw do
  #get 'users/join'
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  
  devise_for :users

  # Define the join route to direct to a join action in UsersController
  #get 'join', to: 'users#join', as: 'join'

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
      get :list
      get :add_new_metadatum
      get :download
      get :create_download
      get :delete_download
      get :download_spreadsheet
      get :download_zip
    end
  end

  resources :copyright_permissions do
    collection do
      get :list
    end
  end

  # Filepond endpoints
  delete 'filepond/remove', to: 'filepond#remove'

  get 'home/about'
  get 'home/join'
  root 'home#index'
end