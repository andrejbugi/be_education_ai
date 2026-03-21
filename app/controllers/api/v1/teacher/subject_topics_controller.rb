module Api
  module V1
    module Teacher
      class SubjectTopicsController < BaseController
        def create
          require_role!("teacher", "admin")
          return if performed?

          subject = subject_scope.find_by(id: params[:subject_id])
          return render_not_found unless subject

          topic = subject.subject_topics.new(subject_topic_params)

          if topic.save
            render json: serialize_topic(topic), status: :created
          else
            render json: { errors: topic.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def subject_scope
          scope = if current_user.has_role?("admin")
                    Subject.all
                  else
                    current_user.subjects.distinct
                  end
          scope = scope.where(school_id: current_school.id) if current_school
          scope
        end

        def subject_topic_params
          params.permit(:name)
        end

        def serialize_topic(topic)
          {
            id: topic.id,
            name: topic.name,
            subject_id: topic.subject_id
          }
        end
      end
    end
  end
end
