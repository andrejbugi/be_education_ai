module Api
  module V1
    class AssignmentsController < BaseController
      include AssignmentResourceSerialization
      include AssignmentStepSerialization

      before_action :set_assignment, only: %i[show update publish]

      def index
        assignments = assignment_scope
        limit, offset = pagination_params

        render json: assignments.order(created_at: :desc).limit(limit).offset(offset).map { |assignment| assignment_payload(assignment) }
      end

      def create
        require_role!("teacher", "admin")
        return if performed?

        result = Assignments::Create.new(teacher: current_user, params: normalized_assignment_params).call
        if result.success?
          log_activity(action: "assignment_created", trackable: result.assignment, metadata: { assignment_id: result.assignment.id })
          render json: assignment_payload(result.assignment.reload, include_steps: true), status: :created
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

        if update_assignment_with_nested_content(@assignment)
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
        @assignment = Assignment.includes({ assignment_steps: :assignment_step_answer_keys }, :classroom, :subject, assignment_resources: { file_attachment: :blob }).find_by(id: params[:id])
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
        ActionController::Parameters.new(assignment_request_params.to_unsafe_h.slice(
          "subject_id",
          "classroom_id",
          "title",
          "description",
          "teacher_notes",
          "assignment_type",
          "due_at",
          "max_points",
          "status",
          "settings"
        )).permit(
          :subject_id,
          :classroom_id,
          :title,
          :description,
          :teacher_notes,
          :assignment_type,
          :due_at,
          :max_points,
          :status,
          settings: {},
          steps: [:position, :title, :content, :prompt, :resource_url, :example_answer, :step_type, :required, { metadata: {} }],
          resources: [:title, :resource_type, :file_url, :external_url, :embed_url, :description, :position, :is_required, :file, { metadata: {} }]
        )
      end

      def update_assignment_params
        ActionController::Parameters.new(assignment_request_params.to_unsafe_h.slice(
          "title",
          "description",
          "teacher_notes",
          "assignment_type",
          "due_at",
          "max_points",
          "status",
          "settings"
        )).permit(
          :title,
          :description,
          :teacher_notes,
          :assignment_type,
          :due_at,
          :max_points,
          :status,
          settings: {}
        )
      end

      def normalized_assignment_params
        permitted = assignment_params.to_h.deep_symbolize_keys
        permitted[:content_json] = normalized_content_blocks(assignment_request_params[:content_json])
        permitted[:steps] = normalized_steps
        permitted[:resources] = normalized_resources
        permitted
      end

      def normalized_steps
        Array(assignment_request_params[:steps]).map.with_index do |step, index|
          raw_step = step.respond_to?(:to_unsafe_h) ? step.to_unsafe_h : step.to_h
          raw_step.symbolize_keys.slice(:position, :title, :content, :prompt, :resource_url, :example_answer, :step_type, :required, :metadata, :evaluation_mode).merge(
            position: raw_step["position"].presence || raw_step[:position].presence || (index + 1),
            content_json: normalized_content_blocks(raw_step["content_json"] || raw_step[:content_json]),
            answer_keys: normalized_answer_keys(raw_step["answer_keys"] || raw_step[:answer_keys])
          )
        end
      end

      def normalized_resources
        Array(assignment_request_params[:resources]).map do |resource|
          raw_resource = resource.respond_to?(:to_unsafe_h) ? resource.to_unsafe_h : resource.to_h
          raw_resource.symbolize_keys.slice(:title, :resource_type, :file_url, :external_url, :embed_url, :description, :position, :is_required, :metadata, :file)
        end
      end

      def normalized_answer_keys(raw_value)
        Array(raw_value).map.with_index do |answer_key, index|
          raw_answer_key = answer_key.respond_to?(:to_unsafe_h) ? answer_key.to_unsafe_h : answer_key.to_h
          raw_answer_key.symbolize_keys.slice(:value, :tolerance, :case_sensitive, :metadata).merge(
            position: raw_answer_key["position"].presence || raw_answer_key[:position].presence || (index + 1)
          )
        end
      end

      def assignment_request_params
        wrapped_params = params[:assignment]
        wrapped_params.is_a?(ActionController::Parameters) ? wrapped_params : params
      end

      def normalized_content_blocks(raw_value)
        return nil if raw_value.nil?

        value = raw_value.respond_to?(:to_unsafe_h) ? raw_value.to_unsafe_h : raw_value
        return [] if value.blank?
        return value.map { |item| item.respond_to?(:to_unsafe_h) ? item.to_unsafe_h : item } if value.is_a?(Array)

        value
      end

      def update_assignment_with_nested_content(assignment)
        Assignment.transaction do
          attributes = update_assignment_params.to_h
          attributes[:content_json] = normalized_content_blocks(assignment_request_params[:content_json]) if assignment_request_params.key?(:content_json)
          assignment.update!(attributes)
          sync_resources!(assignment) if assignment_request_params.key?(:resources)
        end

        true
      rescue ActiveRecord::RecordInvalid
        false
      end

      def sync_resources!(assignment)
        assignment.assignment_resources.destroy_all

        Array(assignment_request_params[:resources]).each_with_index do |resource, index|
          resource = resource.respond_to?(:to_unsafe_h) ? resource.to_unsafe_h.symbolize_keys : resource.to_h.symbolize_keys
          assignment_resource = assignment.assignment_resources.new(
            title: resource[:title],
            resource_type: resource[:resource_type],
            file_url: resource[:file].present? ? nil : resource[:file_url],
            external_url: resource[:external_url],
            embed_url: resource[:embed_url],
            description: resource[:description],
            position: resource[:position].presence || (index + 1),
            is_required: resource[:is_required] || false,
            metadata: resource[:metadata] || {}
          )
          assignment_resource.file.attach(resource[:file]) if resource[:file].present?
          assignment_resource.save!
        end
      end

      def assignment_payload(assignment, include_steps: false, include_submission: false)
        include_answer_keys = can_manage_assignment?(assignment)
        payload = {
          id: assignment.id,
          title: assignment.title,
          description: assignment.description,
          teacher_notes: assignment.teacher_notes,
          content_json: assignment.content_json,
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
          payload[:steps] = assignment.assignment_steps.map { |step| serialize_assignment_step(step, include_answer_keys: include_answer_keys) }
          payload[:resources] = assignment.assignment_resources.map { |resource| serialize_assignment_resource(resource) }
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
