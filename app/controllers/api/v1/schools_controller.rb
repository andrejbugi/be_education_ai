module Api
  module V1
    class SchoolsController < BaseController
      skip_before_action :authenticate_user!, only: :index

      def index
        schools = School.where(active: true).order(:name)
        render json: schools.as_json(only: %i[id name code city active])
      end

      def show
        school = current_user.schools.find_by(id: params[:id])
        return render_not_found unless school

        render json: school.as_json(
          only: %i[id name code city active],
          methods: [],
          include: {
            classrooms: { only: %i[id name grade_level academic_year] },
            subjects: { only: %i[id name code] }
          }
        )
      end
    end
  end
end
