class PasswordResetMailer < ApplicationMailer
  def reset_email(password_reset_id, raw_token)
    @password_reset = PasswordReset.includes(:user).find(password_reset_id)
    @raw_token = raw_token
    @reset_url = "#{frontend_base_url}/reset-password/#{ERB::Util.url_encode(@raw_token)}"

    mail(
      to: @password_reset.user.email,
      subject: "Промена на лозинка"
    )
  end

  private

  def frontend_base_url
    ENV.fetch("FRONTEND_APP_URL", "http://localhost:3000").sub(%r{/\z}, "")
  end
end
