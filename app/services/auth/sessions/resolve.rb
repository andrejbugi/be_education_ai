module Auth
  module Sessions
    class Resolve
      def initialize(raw_token:)
        @raw_token = raw_token
      end

      def call
        return nil if raw_token.blank?

        AuthSession.includes(:user, :current_school).active.find_by(token_digest: AuthSession.digest(raw_token))
      end

      private

      attr_reader :raw_token
    end
  end
end
