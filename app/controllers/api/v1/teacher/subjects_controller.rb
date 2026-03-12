module Api
  module V1
    module Teacher
      class SubjectsController < BaseController
        def index
          require_role!("teacher", "admin")
          return if performed?

          subjects = if current_user.has_role?("admin")
                       Subject.includes(:school).all
                     else
                       current_user.subjects.includes(:school).distinct
                     end
          school = current_school
          subjects = subjects.where(school: school) if school

          render json: subjects.order(:name).as_json(
            only: %i[id name code school_id],
            include: {
              school: { only: %i[id name] }
            }
          )
        end
      end
    end
  end
end
