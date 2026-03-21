module Api
  module V1
    module Teacher
      class SubmissionsController < BaseController
        include AssignmentStepSerialization

        def show
          require_role!("teacher", "admin")
          return if performed?

          submission = Submission.includes(
            :student,
            :submission_step_answers,
            :grades,
            assignment: [
              :subject,
              :subject_topic,
              :classroom,
              :teacher,
              { assignment_steps: :assignment_step_answer_keys }
            ]
          ).find_by(id: params[:id])
          return render_not_found unless submission
          return render_forbidden unless can_review_submission?(submission)

          render json: serialize_submission(submission)
        end

        private

        def can_review_submission?(submission)
          return false unless submission.assignment.classroom.school_id == current_school&.id if current_school
          return true if current_user.has_role?("admin")

          submission.assignment.teacher_id == current_user.id
        end

        def serialize_submission(submission)
          latest_grade = submission.grades.max_by(&:graded_at)

          {
            id: submission.id,
            status: submission.status,
            started_at: submission.started_at,
            submitted_at: submission.submitted_at,
            reviewed_at: submission.reviewed_at,
            late: submission.late,
            total_score: submission.total_score,
            feedback: submission.feedback,
            student: {
              id: submission.student_id,
              full_name: submission.student.full_name,
              email: submission.student.email
            },
            assignment: {
              id: submission.assignment_id,
              title: submission.assignment.title,
              assignment_type: submission.assignment.assignment_type,
              due_at: submission.assignment.due_at,
              subject: {
                id: submission.assignment.subject_id,
                name: submission.assignment.subject.name
              },
              subject_topic_id: submission.assignment.subject_topic_id,
              subject_topic: submission.assignment.subject_topic && {
                id: submission.assignment.subject_topic.id,
                name: submission.assignment.subject_topic.name
              },
              classroom: {
                id: submission.assignment.classroom_id,
                name: submission.assignment.classroom.name
              },
              teacher: {
                id: submission.assignment.teacher_id,
                full_name: submission.assignment.teacher.full_name
              }
            },
            steps: submission.assignment.assignment_steps.map { |step| serialize_assignment_step(step, include_answer_keys: true) },
            step_answers: submission.submission_step_answers.order(:assignment_step_id).map do |step_answer|
              {
                id: step_answer.id,
                assignment_step_id: step_answer.assignment_step_id,
                answer_text: step_answer.answer_text,
                answer_data: step_answer.answer_data,
                status: step_answer.status,
                answered_at: step_answer.answered_at,
                created_at: step_answer.created_at,
                updated_at: step_answer.updated_at
              }
            end,
            grade: latest_grade && {
              id: latest_grade.id,
              submission_id: latest_grade.submission_id,
              teacher_id: latest_grade.teacher_id,
              score: latest_grade.score,
              max_score: latest_grade.max_score,
              feedback: latest_grade.feedback,
              graded_at: latest_grade.graded_at
            }
          }
        end
      end
    end
  end
end
