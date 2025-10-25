Rails.application.routes.draw do
  scope path: '/golden_deployment' do
    root "examples#index"

    resources :examples, only: [:index, :show]

    get "dashboard" => "dashboard#index", as: :dashboard

    resources :apps, only: [:index, :show] do
      member do
        post :scan
        post :scan_all
      end
      collection do
        post :discover
      end
    end

    resources :quality_scans, only: [:index]

    get "up" => "rails/health#show", as: :rails_health_check
  end
end
