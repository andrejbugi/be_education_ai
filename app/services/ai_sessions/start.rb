module AiSessions
  class Start
    Result = Struct.new(:success?, :session, :errors, keyword_init: true)

    def initialize(user:, school:, params:)
      @user = user
      @school = school
      @params = params
    end

    def call
      now = Time.current
      session = school.ai_sessions.new(session_attributes.merge(user: user, started_at: now, last_activity_at: now))

      if session.save
        Result.new(success?: true, session: session, errors: [])
      else
        Result.new(success?: false, session: session, errors: session.errors.full_messages)
      end
    end

    private

    attr_reader :user, :school, :params

    def session_attributes
      params.slice(:assignment_id, :submission_id, :subject_id, :title, :session_type, :status, :context_data)
    end
  end
end
