module Auth
  module Sessions
    class RevokeAllForUser
      def initialize(user:)
        @user = user
      end

      def call
        return if user.blank?

        user.auth_sessions.active.update_all(revoked_at: Time.current)
      end

      private

      attr_reader :user
    end
  end
end
