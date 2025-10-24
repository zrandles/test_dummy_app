Rails.application.routes.draw do
  scope path: '/code_quality' do
    root "examples#index"

    resources :examples, only: [:index, :show]

    # API endpoints with authentication
    namespace :api do
      resources :examples, only: [:index] do
        collection do
          post :bulk_upsert
        end
      end
    end

    get "up" => "rails/health#show", as: :rails_health_check
  end
end
