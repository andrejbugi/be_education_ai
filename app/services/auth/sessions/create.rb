module Auth
  module Sessions
    class Create
      Result = Struct.new(:success?, :auth_session, :raw_token, :errors, keyword_init: true)

      def initialize(user:, school:, request:)
        @user = user
        @school = school
        @request = request
      end

      def call
        raw_token = SecureRandom.urlsafe_base64(48)
        auth_session = user.auth_sessions.create!(
          current_school: school,
          token_digest: AuthSession.digest(raw_token),
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          expires_at: AuthSession::SESSION_LIFETIME.from_now,
          last_seen_at: Time.current
        )

        Result.new(success?: true, auth_session: auth_session, raw_token: raw_token, errors: [])
      rescue ActiveRecord::RecordInvalid => e
        Result.new(success?: false, auth_session: nil, raw_token: nil, errors: e.record.errors.full_messages)
      end

      private

      attr_reader :user, :school, :request
    end
  end
end
