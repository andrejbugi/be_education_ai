module Api
  module V1
    class DiscussionSpacesController < BaseController
      include DiscussionSerialization

      def index
        if assignment_scope_lookup?
          return render_assignment_scope_result
        end

        spaces = filtered_spaces
        render json: spaces.map { |space| serialize_discussion_space(space) }
      end

      def show
        space = base_scope.find_by(id: params[:id])
        return render_not_found unless space
        return render_forbidden unless DiscussionSpacePolicy.new(current_user, space).show?

        render json: serialize_discussion_space(space)
      end

      private

      def assignment_scope_lookup?
        params[:assignment_id].present? && (params[:space_type].blank? || params[:space_type] == "assignment")
      end

      def render_assignment_scope_result
        result = DiscussionSpaces::ResolveForScope.new(
          user: current_user,
          school: school_context,
          params: space_filter_params.to_h.symbolize_keys
        ).call

        return render_not_found if result.not_found
        return render_forbidden if result.forbidden

        if result.success?
          render json: [serialize_discussion_space(preloaded_space(result.space.id))]
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      def base_scope
        scope = DiscussionSpace.includes(:school, :assignment, :classroom, :subject)
        scope = scope.where(school_id: school_context.id) if school_context
        scope
      end

      def filtered_spaces
        scope = base_scope
        scope = scope.where(space_type: params[:space_type]) if params[:space_type].present?
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(assignment_id: params[:assignment_id]) if params[:assignment_id].present?
        scope = scope.where(classroom_id: params[:classroom_id]) if params[:classroom_id].present?
        scope = scope.where(subject_id: params[:subject_id]) if params[:subject_id].present?

        scope.select { |space| DiscussionSpacePolicy.new(current_user, space).show? }
      end

      def school_context
        current_school || current_user.schools.first
      end

      def preloaded_space(id)
        DiscussionSpace.includes(:school, :assignment, :classroom, :subject).find(id)
      end

      def space_filter_params
        params.permit(:space_type, :status, :assignment_id, :classroom_id, :subject_id)
      end
    end
  end
end
