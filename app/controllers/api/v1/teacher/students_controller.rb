module Api
  module V1
    module Teacher
      class StudentsController < BaseController
        def show
          require_role!("teacher", "admin")
          return if performed?

          student = User.find_by(id: params[:id])
          return render_not_found unless student
          return render_forbidden unless accessible_student?(student)

          render json: {
            student: student.as_json(only: %i[id first_name last_name email]),
            profile: student.student_profile,
            classrooms: student.student_classrooms.select(:id, :name, :grade_level),
            submissions: student.submissions.order(created_at: :desc).limit(20).as_json(
              only: %i[id assignment_id status submitted_at total_score],
              include: {
                assignment: { only: %i[id title due_at] }
              }
            )
          }
        end

        private

        def accessible_student?(student)
          return true if current_user.has_role?("admin")

          teacher_classroom_ids = current_user.teaching_classroom_ids
          (student.student_classroom_ids & teacher_classroom_ids).any?
        end
      end
    end
  end
end
