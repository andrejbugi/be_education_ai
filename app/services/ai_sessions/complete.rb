module AiSessions
  class Complete
    Result = Struct.new(:success?, :session, :errors, keyword_init: true)

    def initialize(session:)
      @session = session
    end

    def call
      session.update!(status: :completed, ended_at: Time.current, last_activity_at: Time.current)
      Result.new(success?: true, session: session, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, session: e.record, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :session
  end
end
