Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "auth/login", to: "auth#login"
      delete "auth/logout", to: "auth#logout"
      get "auth/me", to: "auth#me"

      resources :schools, only: %i[index show]
      resource :profile, only: %i[show update], controller: "profile"
      resources :announcements, only: %i[index create show update] do
        post :publish, on: :member
        post :archive, on: :member
      end
      resources :attendance_records, only: %i[index create update]
      resources :ai_sessions, only: %i[index create show update] do
        post :close, on: :member
        resources :messages, only: %i[index create], controller: "ai_messages"
      end

      get "classrooms/:classroom_id/attendance", to: "classroom_attendance#show"
      get "students/:id/attendance", to: "student_attendance#show"
      post "classrooms/:classroom_id/homeroom_assignment", to: "homeroom_assignments#create"
      patch "homeroom_assignments/:id", to: "homeroom_assignments#update"
      get "students/:id/performance_snapshots", to: "student_performance_snapshots#index"
      get "classrooms/:id/performance_overview", to: "classroom_performance_overviews#show"

      namespace :teacher do
        get "dashboard", to: "dashboards#show"
        get "homerooms", to: "homerooms#index"
        resources :classrooms, only: %i[index show]
        resources :subjects, only: :index
        resources :students, only: :show
      end

      resources :assignments, only: %i[index create show update] do
        post :publish, on: :member
        resources :steps, only: %i[create update], controller: "assignment_steps"
        resources :resources, only: %i[create update destroy], controller: "assignment_resources"
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
        get "performance", to: "performance#show"
        resources :assignments, only: %i[index show]
      end
    end
  end
end
