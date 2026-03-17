module DiscussionThreads
  class UpdateModeration
    Result = Struct.new(:success?, :thread, :errors, keyword_init: true)

    def initialize(thread:, actor:, attributes:)
      @thread = thread
      @actor = actor
      @attributes = attributes
    end

    def call
      return failure(["You are not allowed to moderate this thread"]) unless policy.moderate?

      thread.update!(attributes)
      Result.new(success?: true, thread: thread, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :thread, :actor, :attributes

    def policy
      @policy ||= DiscussionThreadPolicy.new(actor, thread)
    end

    def failure(errors)
      Result.new(success?: false, thread: thread, errors: Array(errors))
    end
  end
end
