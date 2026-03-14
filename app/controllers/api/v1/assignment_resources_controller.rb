module Api
  module V1
    class AssignmentResourcesController < BaseController
      include AssignmentResourceSerialization

      before_action :set_assignment
      before_action :require_teacher_or_admin!
      before_action :ensure_manageable_assignment!
      before_action :set_resource, only: %i[update destroy]

      def create
        resource = @assignment.assignment_resources.new(resource_params.except(:assignment_id, :file, :remove_file))
        attach_uploaded_file(resource, resource_params[:file])
        set_next_position(resource) if resource.position.blank?

        if resource.save
          render json: serialize_assignment_resource(resource), status: :created
        else
          render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        @resource.assign_attributes(resource_params.except(:assignment_id, :file, :remove_file))
        remove_uploaded_file(@resource) if remove_file?
        attach_uploaded_file(@resource, resource_params[:file])

        if @resource.save
          render json: serialize_assignment_resource(@resource)
        else
          render json: { errors: @resource.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @resource.destroy!
        head :no_content
      end

      private

      def set_assignment
        @assignment = Assignment.find_by(id: params[:assignment_id])
        render_not_found unless @assignment
      end

      def set_resource
        @resource = @assignment.assignment_resources.find_by(id: params[:id])
        render_not_found unless @resource
      end

      def ensure_manageable_assignment!
        return if current_user.has_role?("admin") || @assignment.teacher_id == current_user.id

        render_forbidden
      end

      def require_teacher_or_admin!
        require_role!("teacher", "admin")
      end

      def resource_params
        params.permit(:assignment_id, :title, :resource_type, :file_url, :external_url, :embed_url, :description, :position, :is_required, :file, :remove_file, metadata: {})
      end

      def remove_file?
        ActiveModel::Type::Boolean.new.cast(resource_params[:remove_file])
      end

      def attach_uploaded_file(resource, uploaded_file)
        return if uploaded_file.blank?

        resource.file_url = nil
        resource.file.attach(uploaded_file)
      end

      def remove_uploaded_file(resource)
        return unless resource.file.attached?

        resource.file.purge
      end

      def set_next_position(resource)
        resource.position = @assignment.assignment_resources.maximum(:position).to_i + 1
      end
    end
  end
end
