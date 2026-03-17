module Api
  module V1
    class DiscussionThreadsController < BaseController
      include DiscussionSerialization

      before_action :set_discussion_space, only: %i[index create]
      before_action :set_discussion_thread, only: %i[show lock unlock pin unpin archive]

      def index
        return render_forbidden unless DiscussionSpacePolicy.new(current_user, @discussion_space).show?

        threads = @discussion_space.discussion_threads.includes(:creator, discussion_space: %i[school assignment classroom subject])
        threads = threads.where(status: params[:status]) if params[:status].present?
        threads = threads.active unless params[:status].present?
        render json: threads.ordered_for_space.map { |thread| serialize_discussion_thread(thread) }
      end

      def show
        return render_forbidden unless DiscussionThreadPolicy.new(current_user, @discussion_thread).show?

        render json: serialize_discussion_thread(@discussion_thread, include_space: true)
      end

      def create
        result = DiscussionThreads::Create.new(
          space: @discussion_space,
          creator: current_user,
          params: thread_params.to_h.symbolize_keys
        ).call

        if result.success?
          log_activity(
            action: "discussion_thread_created",
            trackable: result.thread,
            metadata: { discussion_space_id: @discussion_space.id, discussion_thread_id: result.thread.id }
          )
          render json: serialize_discussion_thread(reload_thread(result.thread.id), include_space: true), status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      def lock
        moderate_thread(locked: true)
      end

      def unlock
        moderate_thread(locked: false)
      end

      def pin
        moderate_thread(pinned: true)
      end

      def unpin
        moderate_thread(pinned: false)
      end

      def archive
        moderate_thread(status: "archived")
      end

      private

      def set_discussion_space
        @discussion_space = DiscussionSpace.includes(:school, :assignment, :classroom, :subject).find_by(id: params[:discussion_space_id])
        render_not_found unless @discussion_space
      end

      def set_discussion_thread
        @discussion_thread = DiscussionThread.includes(:creator, discussion_space: %i[school assignment classroom subject]).find_by(id: params[:id])
        render_not_found unless @discussion_thread
      end

      def thread_params
        params.permit(:title, :body)
      end

      def reload_thread(id)
        DiscussionThread.includes(:creator, discussion_space: %i[school assignment classroom subject]).find(id)
      end

      def moderate_thread(attributes)
        result = DiscussionThreads::UpdateModeration.new(
          thread: @discussion_thread,
          actor: current_user,
          attributes: attributes
        ).call

        if result.success?
          render json: serialize_discussion_thread(reload_thread(@discussion_thread.id), include_space: true)
        else
          render json: { errors: result.errors }, status: :forbidden
        end
      end
    end
  end
end
