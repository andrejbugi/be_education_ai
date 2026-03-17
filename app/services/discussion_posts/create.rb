module DiscussionPosts
  class Create
    Result = Struct.new(:success?, :post, :errors, keyword_init: true)

    def initialize(thread:, author:, params:)
      @thread = thread
      @author = author
      @params = params
    end

    def call
      return failure(["You are not allowed to post in this thread"]) unless policy.create_post?

      post = nil

      DiscussionPost.transaction do
        post = thread.discussion_posts.create!(
          author: author,
          body: params[:body],
          parent_post_id: params[:parent_post_id],
          status: "visible"
        )

        thread.update!(last_post_at: post.created_at)
      end

      Result.new(success?: true, post: post, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :thread, :author, :params

    def policy
      @policy ||= DiscussionThreadPolicy.new(author, thread)
    end

    def failure(errors)
      Result.new(success?: false, post: nil, errors: Array(errors))
    end
  end
end
