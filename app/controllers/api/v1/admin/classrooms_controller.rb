module Api
  module V1
    module Admin
      class ClassroomsController < BaseController
        before_action :require_current_school!
        before_action :set_classroom, only: %i[show update destroy]

        def index
          relation = current_school.classrooms.includes(:teacher_classrooms, :classroom_users, :assignments).order(:name)
          if params[:q].present?
            query = "%#{params[:q].strip}%"
            relation = relation.where("classrooms.name ILIKE ? OR classrooms.grade_level ILIKE ? OR classrooms.academic_year ILIKE ?", query, query, query)
          end
          limit, offset = pagination_params

          render json: relation.limit(limit).offset(offset).map { |classroom| serialize_admin_classroom(classroom) }
        end

        def create
          classroom = current_school.classrooms.new(classroom_params)

          if classroom.save
            render json: serialize_admin_classroom(classroom), status: :created
          else
            render json: { errors: classroom.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def show
          render json: serialize_admin_classroom(@classroom)
        end

        def update
          if @classroom.update(classroom_params)
            render json: serialize_admin_classroom(@classroom)
          else
            render json: { errors: @classroom.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          result = ::Admin::Classrooms::Destroy.new(classroom: @classroom).call

          if result.success?
            head :no_content
          else
            render json: { errors: result.errors, blockers: result.blockers }, status: :unprocessable_entity
          end
        end

        private

        def set_classroom
          @classroom = current_school.classrooms.find_by(id: params[:id])
          render_not_found unless @classroom
        end

        def classroom_params
          params.permit(:name, :grade_level, :academic_year)
        end
      end
    end
  end
end
