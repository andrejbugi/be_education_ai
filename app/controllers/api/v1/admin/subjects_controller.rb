module Api
  module V1
    module Admin
      class SubjectsController < BaseController
        before_action :require_current_school!
        before_action :set_subject, only: %i[show update destroy]

        def index
          relation = current_school.subjects.includes(:subject_topics, :teacher_subjects, :assignments).order(:name)
          if params[:q].present?
            query = "%#{params[:q].strip}%"
            relation = relation.where("subjects.name ILIKE ? OR subjects.code ILIKE ?", query, query)
          end
          limit, offset = pagination_params

          render json: relation.limit(limit).offset(offset).map { |subject| serialize_admin_subject(subject) }
        end

        def create
          subject = current_school.subjects.new(subject_params)

          if subject.save
            render json: serialize_admin_subject(subject), status: :created
          else
            render json: { errors: subject.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def show
          render json: serialize_admin_subject(@subject)
        end

        def update
          if @subject.update(subject_params)
            render json: serialize_admin_subject(@subject)
          else
            render json: { errors: @subject.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          result = ::Admin::Subjects::Destroy.new(subject: @subject).call

          if result.success?
            head :no_content
          else
            render json: { errors: result.errors, blockers: result.blockers }, status: :unprocessable_entity
          end
        end

        private

        def set_subject
          @subject = current_school.subjects.find_by(id: params[:id])
          render_not_found unless @subject
        end

        def subject_params
          params.permit(:name, :code)
        end
      end
    end
  end
end
