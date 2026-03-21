module Api
  module V1
    module Teacher
      class SubjectsController < BaseController
        def index
          require_role!("teacher", "admin")
          return if performed?

          subjects = if current_user.has_role?("admin")
                       Subject.includes(:school, :subject_topics).all
                     else
                       current_user.subjects.includes(:school, :subject_topics).distinct
                     end
          school = current_school
          subjects = subjects.where(school: school) if school
          limit, offset = pagination_params

          payload = subjects.order(:name).limit(limit).offset(offset).map do |subject|
            {
              id: subject.id,
              name: subject.name,
              code: subject.code,
              school_id: subject.school_id,
              school: {
                id: subject.school.id,
                name: subject.school.name
              },
              topics: subject.subject_topics.order(:name).map do |topic|
                {
                  id: topic.id,
                  name: topic.name
                }
              end
            }
          end

          render json: payload
        end
      end
    end
  end
end
