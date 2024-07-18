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
  root 'home#index'
end
