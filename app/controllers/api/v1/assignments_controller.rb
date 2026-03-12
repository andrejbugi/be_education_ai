module Api
  module V1
    class AssignmentsController < BaseController
      before_action :set_assignment, only: %i[show update publish]

      def index
        assignments = assignment_scope
        limit, offset = pagination_params

        render json: assignments.order(created_at: :desc).limit(limit).offset(offset).map { |assignment| assignment_payload(assignment) }
      end

      def create
        require_role!("teacher", "admin")
        return if performed?

        result = Assignments::Create.new(teacher: current_user, params: assignment_params.to_h.symbolize_keys).call
        if result.success?
          log_activity(action: "assignment_created", trackable: result.assignment, metadata: { assignment_id: result.assignment.id })
          render json: assignment_payload(result.assignment), status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      def show
        return render_forbidden unless can_view_assignment?(@assignment)

        render json: assignment_payload(@assignment, include_steps: true, include_submission: true)
      end

      def update
        require_role!("teacher", "admin")
        return if performed?
        return render_forbidden unless can_manage_assignment?(@assignment)

        if @assignment.update(update_assignment_params)
          render json: assignment_payload(@assignment.reload, include_steps: true)
        else
          render json: { errors: @assignment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def publish
        require_role!("teacher", "admin")
        return if performed?
        return render_forbidden unless can_manage_assignment?(@assignment)

        result = Assignments::Publish.new(assignment: @assignment, actor: current_user).call
        if result.success?
          log_activity(action: "assignment_published", trackable: @assignment, metadata: { assignment_id: @assignment.id })
          render json: assignment_payload(@assignment.reload)
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def set_assignment
        @assignment = Assignment.includes(:assignment_steps, :classroom, :subject).find_by(id: params[:id])
        render_not_found unless @assignment
      end

      def assignment_scope
        scope = Assignment.includes(:classroom, :subject, :teacher)
        school = current_school
        scope = scope.for_school(school.id) if school

        if current_user.has_any_role?("teacher", "admin")
          return scope if current_user.has_role?("admin")

          scope.where(teacher_id: current_user.id)
        else
          scope.joins(classroom: :classroom_users)
               .where(classroom_users: { user_id: current_user.id })
        end
      end

      def can_manage_assignment?(assignment)
        current_user.has_role?("admin") || assignment.teacher_id == current_user.id
      end

      def can_view_assignment?(assignment)
        return true if can_manage_assignment?(assignment)

        assignment.classroom.students.exists?(id: current_user.id)
      end

      def assignment_params
        params.permit(
          :subject_id,
          :classroom_id,
          :title,
          :description,
          :assignment_type,
          :due_at,
          :max_points,
          :status,
          settings: {},
          steps: [:position, :title, :content, :step_type, :required, { metadata: {} }]
        )
      end

      def update_assignment_params
        params.permit(:title, :description, :assignment_type, :due_at, :max_points, :status, settings: {})
      end

      def assignment_payload(assignment, include_steps: false, include_submission: false)
        payload = {
          id: assignment.id,
          title: assignment.title,
          description: assignment.description,
          assignment_type: assignment.assignment_type,
          status: assignment.status,
          due_at: assignment.due_at,
          published_at: assignment.published_at,
          max_points: assignment.max_points,
          subject: {
            id: assignment.subject_id,
            name: assignment.subject.name
          },
          classroom: {
            id: assignment.classroom_id,
            name: assignment.classroom.name
          },
          teacher: {
            id: assignment.teacher_id,
            full_name: assignment.teacher.full_name
          }
        }

        if include_steps
          payload[:steps] = assignment.assignment_steps.map do |step|
            {
              id: step.id,
              position: step.position,
              title: step.title,
              content: step.content,
              step_type: step.step_type,
              required: step.required,
              metadata: step.metadata
            }
          end
        end

        if include_submission && current_user.has_role?("student")
          submission = assignment.submissions.find_by(student_id: current_user.id)
          payload[:current_submission] = submission&.as_json(only: %i[id status started_at submitted_at total_score late])
        end

        payload
      end
    end
  end
end
