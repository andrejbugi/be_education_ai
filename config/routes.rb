Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "auth/login", to: "auth#login"
      delete "auth/logout", to: "auth#logout"
      get "auth/me", to: "auth#me"

      resources :schools, only: %i[index show]
      resource :profile, only: %i[show update], controller: "profile"

      namespace :teacher do
        get "dashboard", to: "dashboards#show"
        resources :classrooms, only: %i[index show]
        resources :subjects, only: :index
        resources :students, only: :show
      end

      resources :assignments, only: %i[index create show update] do
        post :publish, on: :member
        resources :steps, only: %i[create update], controller: "assignment_steps"
        resources :submissions, only: :create, controller: "submissions"
      end

      resources :submissions, only: :update do
        post :submit, on: :member
        resources :grades, only: :create, controller: "grades"
      end

      resources :comments, only: %i[index create]
      resources :notifications, only: :index do
        post :mark_as_read, on: :member
      end

      namespace :calendar do
        resources :events, only: %i[index create update]
      end

      namespace :student do
        get "dashboard", to: "dashboards#show"
        resources :assignments, only: %i[index show]
      end
    end
  end
end
