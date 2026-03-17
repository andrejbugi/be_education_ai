module Api
  module V1
    class DiscussionPostsController < BaseController
      include DiscussionSerialization

      before_action :set_discussion_thread, only: %i[index create]
      before_action :set_discussion_post, only: %i[hide unhide]

      def index
        thread_policy = DiscussionThreadPolicy.new(current_user, @discussion_thread)
        return render_forbidden unless thread_policy.show?

        posts = @discussion_thread.discussion_posts.includes(:author, :replies)
        posts = posts.where.not(status: "deleted")
        posts = posts.where(status: "visible") unless thread_policy.moderate?

        render json: posts.order(:created_at, :id).map { |post| serialize_discussion_post(post) }
      end

      def create
        result = DiscussionPosts::Create.new(
          thread: @discussion_thread,
          author: current_user,
          params: post_params.to_h.symbolize_keys
        ).call

        if result.success?
          log_activity(
            action: "discussion_post_created",
            trackable: result.post,
            metadata: { discussion_thread_id: @discussion_thread.id, discussion_post_id: result.post.id }
          )
          render json: serialize_discussion_post(reload_post(result.post.id)), status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      def hide
        update_visibility("hidden")
      end

      def unhide
        update_visibility("visible")
      end

      private

      def set_discussion_thread
        @discussion_thread = DiscussionThread.includes(:creator, discussion_space: %i[school assignment classroom subject]).find_by(id: params[:discussion_thread_id])
        render_not_found unless @discussion_thread
      end

      def set_discussion_post
        @discussion_post = DiscussionPost.includes(:author, discussion_thread: { discussion_space: %i[school assignment classroom subject] }).find_by(id: params[:id])
        render_not_found unless @discussion_post
      end

      def post_params
        params.permit(:body, :parent_post_id)
      end

      def reload_post(id)
        DiscussionPost.includes(:author, :replies).find(id)
      end

      def update_visibility(status)
        result = DiscussionPosts::UpdateVisibility.new(
          post: @discussion_post,
          actor: current_user,
          status: status
        ).call

        if result.success?
          render json: serialize_discussion_post(reload_post(@discussion_post.id))
        else
          render json: { errors: result.errors }, status: :forbidden
        end
      end
    end
  end
end
