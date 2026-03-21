module Auth
  module Sessions
    class Revoke
      def initialize(auth_session:)
        @auth_session = auth_session
      end

      def call
        return if auth_session.blank?

        auth_session.revoke!
      end

      private

      attr_reader :auth_session
    end
  end
end
