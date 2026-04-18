module Auth
  module PasswordResets
    class Confirm
      Result = Struct.new(:success?, :password_reset, :user, :errors, keyword_init: true)

      def initialize(token:, params:)
        @token = token
        @params = params
      end

      def call
        password_reset = Auth::PasswordResets::Resolve.new(token: token).call
        return Result.new(success?: false, password_reset: nil, user: nil, errors: ["Password reset not found"]) unless password_reset
        return disallowed_result(password_reset, "Password reset link has already been used") if password_reset.used_at?
        return disallowed_result(password_reset, "Password reset link has expired") if password_reset.expired_now?

        user = password_reset.user

        User.transaction do
          user.password = params[:password]
          user.password_confirmation = params[:password_confirmation]
          user.save!

          password_reset.update!(used_at: Time.current)
          Auth::Sessions::RevokeAllForUser.new(user: user).call
        end

        Result.new(success?: true, password_reset: password_reset, user: user, errors: [])
      rescue ActiveRecord::RecordInvalid => e
        Result.new(success?: false, password_reset: password_reset, user: password_reset&.user, errors: e.record.errors.full_messages)
      end

      private

      attr_reader :token, :params

      def disallowed_result(password_reset, error_message)
        Result.new(success?: false, password_reset: password_reset, user: password_reset.user, errors: [error_message])
      end
    end
  end
end
