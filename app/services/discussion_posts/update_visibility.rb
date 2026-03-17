module DiscussionPosts
  class UpdateVisibility
    Result = Struct.new(:success?, :post, :errors, keyword_init: true)

    def initialize(post:, actor:, status:)
      @post = post
      @actor = actor
      @status = status
    end

    def call
      return failure(["You are not allowed to moderate this post"]) unless policy.moderate?

      post.update!(status: status)
      Result.new(success?: true, post: post, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :post, :actor, :status

    def policy
      @policy ||= DiscussionPostPolicy.new(actor, post)
    end

    def failure(errors)
      Result.new(success?: false, post: post, errors: Array(errors))
    end
  end
end
