module Auth
  module PasswordResets
    class Resolve
      def initialize(token:)
        @token = token
      end

      def call
        PasswordReset.includes(:user).find_by(token_digest: PasswordReset.digest(token))
      end

      private

      attr_reader :token
    end
  end
end
