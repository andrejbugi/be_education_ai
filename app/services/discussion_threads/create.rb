module DiscussionThreads
  class Create
    Result = Struct.new(:success?, :thread, :errors, keyword_init: true)

    def initialize(space:, creator:, params:)
      @space = space
      @creator = creator
      @params = params
    end

    def call
      return failure(["You are not allowed to create a thread in this space"]) unless policy.create_thread?

      thread = space.discussion_threads.new(
        creator: creator,
        title: params[:title],
        body: params[:body],
        status: "active",
        pinned: false,
        locked: false,
        last_post_at: Time.current
      )
      thread.save!

      Result.new(success?: true, thread: thread, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :space, :creator, :params

    def policy
      @policy ||= DiscussionSpacePolicy.new(creator, space)
    end

    def failure(errors)
      Result.new(success?: false, thread: nil, errors: Array(errors))
    end
  end
end
