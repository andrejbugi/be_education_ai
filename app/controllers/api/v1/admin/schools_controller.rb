module Api
  module V1
    module Admin
      class SchoolsController < BaseController
        before_action :set_school, only: %i[show update deactivate reactivate]

        def index
          limit, offset = pagination_params
          schools = admin_schools_scope.order(:name).limit(limit).offset(offset)

          render json: schools.map { |school| serialize_admin_school(school) }
        end

        def create
          result = ::Admin::Schools::Create.new(admin: current_user, params: school_params.to_h.symbolize_keys).call

          if result.success?
            render json: serialize_admin_school(result.school), status: :created
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        def show
          render json: serialize_admin_school(@school)
        end

        def update
          result = ::Admin::Schools::Update.new(school: @school, params: school_params.to_h.symbolize_keys).call

          if result.success?
            render json: serialize_admin_school(result.school)
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        def deactivate
          set_active(false)
        end

        def reactivate
          set_active(true)
        end

        private

        def set_school
          @school = admin_schools_scope.find_by(id: params[:id])
          render_not_found unless @school
        end

        def school_params
          params.permit(:name, :code, :city, :active, settings: {})
        end

        def set_active(active)
          result = ::Admin::Schools::SetActive.new(school: @school, active: active).call

          if result.success?
            render json: serialize_admin_school(result.school)
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
