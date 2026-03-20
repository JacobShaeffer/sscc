Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  
  devise_for :users, controllers: {
    registrations: 'my_devise/registrations'
  }

  resources :metadata_types, except: [:new, :show] do
    collection do
      get :search
      get :list
    end
    scope module: 'metadata_types' do
      resources :metadata, except: [:index, :new, :show] do
        member do
          get :review
          get :info
          get :replace
        end
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
      get :auto_complete
      get :add_new_metadatum
      get :add_existing_metadatum
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

  get 'profile', to: 'profiles#show', as: :profile

  get 'home/about'
  get 'home/join'
  get 'home/welcome'
  root 'home#index'
end
