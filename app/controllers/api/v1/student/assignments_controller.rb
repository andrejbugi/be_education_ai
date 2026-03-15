module Api
  module V1
    module Student
      class AssignmentsController < BaseController
        include AssignmentResourceSerialization
        include AssignmentStepSerialization

        before_action :require_student!

        def index
          assignments = Assignment.joins(classroom: :classroom_users)
                                  .includes(:subject, :teacher, :classroom)
                                  .where(classroom_users: { user_id: current_user.id })
                                  .where(status: [Assignment.statuses[:published], Assignment.statuses[:scheduled]])

          school = current_school
          assignments = assignments.for_school(school.id) if school

          limit, offset = pagination_params

          render json: assignments.order(due_at: :asc).limit(limit).offset(offset).map { |assignment| serialize_assignment(assignment) }
        end

        def show
          assignment = Assignment.includes({ assignment_steps: :assignment_step_answer_keys }, :subject, :teacher, :classroom, assignment_resources: { file_attachment: :blob })
                                 .find_by(id: params[:id])
          return render_not_found unless assignment

          return render_forbidden unless assignment.classroom.students.exists?(id: current_user.id)

          submission = Submission.includes(:submission_step_answers).find_by(assignment: assignment, student: current_user)

          render json: serialize_assignment(assignment, include_steps: true).merge(
            submission: serialize_submission(submission)
          )
        end

        private

        def require_student!
          require_role!("student")
        end

        def serialize_assignment(assignment, include_steps: false)
          payload = {
            id: assignment.id,
            title: assignment.title,
            description: assignment.description,
            teacher_notes: assignment.teacher_notes,
            content_json: assignment.content_json,
            status: assignment.status,
            due_at: assignment.due_at,
            subject: {
              id: assignment.subject_id,
              name: assignment.subject.name
            },
            teacher: {
              id: assignment.teacher_id,
              full_name: assignment.teacher.full_name
            },
            classroom: {
              id: assignment.classroom_id,
              name: assignment.classroom.name
            }
          }

          if include_steps
            payload[:steps] = assignment.assignment_steps.map { |step| serialize_assignment_step(step) }
            payload[:resources] = assignment.assignment_resources.map { |resource| serialize_assignment_resource(resource) }
          end

          payload
        end

        def serialize_submission(submission)
          return nil unless submission

          {
            id: submission.id,
            status: submission.status,
            started_at: submission.started_at,
            submitted_at: submission.submitted_at,
            total_score: submission.total_score,
            late: submission.late,
            step_answers: submission.submission_step_answers.order(:assignment_step_id).map do |step_answer|
              {
                id: step_answer.id,
                assignment_step_id: step_answer.assignment_step_id,
                answer_text: step_answer.answer_text,
                answer_data: step_answer.answer_data,
                status: step_answer.status,
                answered_at: step_answer.answered_at
              }
            end
          }
        end
      end
    end
  end
end
