module Auth
  module PasswordResets
    class Request
      Result = Struct.new(:success?, :password_reset, :email_sent, :errors, keyword_init: true)

      def initialize(email:)
        @raw_email = email
      end

      def call
        user = User.find_by(email: normalized_email)
        return success_result(password_reset: nil, email_sent: false) unless user&.active?

        raw_token = SecureRandom.urlsafe_base64(32)
        password_reset = nil

        PasswordReset.transaction do
          password_reset = PasswordReset.find_or_initialize_by(user: user)
          password_reset.assign_attributes(
            token_digest: PasswordReset.digest(raw_token),
            expires_at: PasswordReset::RESET_LIFETIME.from_now,
            used_at: nil,
            last_sent_at: Time.current
          )
          password_reset.save!
        end

        PasswordResetMailer.reset_email(password_reset.id, raw_token).deliver_now
        success_result(password_reset: password_reset, email_sent: true)
      rescue ActiveRecord::RecordInvalid => e
        Result.new(success?: false, password_reset: password_reset, email_sent: false, errors: e.record.errors.full_messages)
      end

      private

      attr_reader :raw_email

      def normalized_email
        raw_email.to_s.downcase.strip
      end

      def success_result(password_reset:, email_sent:)
        Result.new(success?: true, password_reset: password_reset, email_sent: email_sent, errors: [])
      end
    end
  end
end
