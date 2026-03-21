module Api
  module V1
    class SchoolsController < BaseController
      skip_before_action :authenticate_user!, only: :index

      def index
        limit, offset = pagination_params
        schools = School.where(active: true).order(:name).limit(limit).offset(offset)
        render json: schools.as_json(only: %i[id name code city active])
      end

      def show
        school = current_user.schools.find_by(id: params[:id])
        return render_not_found unless school

        render json: {
          id: school.id,
          name: school.name,
          code: school.code,
          city: school.city,
          active: school.active,
          classrooms: school.classrooms.select(:id, :name, :grade_level, :academic_year).map do |classroom|
            {
              id: classroom.id,
              name: classroom.name,
              grade_level: classroom.grade_level,
              academic_year: classroom.academic_year
            }
          end,
          subjects: school.subjects.includes(:subject_topics).order(:name).map do |subject|
            topics = subject.subject_topics.order(:name).map do |topic|
              {
                id: topic.id,
                name: topic.name
              }
            end

            {
              id: subject.id,
              name: subject.name,
              code: subject.code,
              topics: topics,
              subject_topics: topics
            }
          end
        }
      end
    end
  end
end
