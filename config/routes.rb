Rails.application.routes.draw do
  scope path: '/test_dummy_app' do
    root "examples#index"

    resources :examples, only: [:index, :show]

    get "up" => "rails/health#show", as: :rails_health_check
  end
end
