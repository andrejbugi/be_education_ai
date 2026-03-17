module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      payload = Auth::JwtToken.decode(token_from_request)
      user = payload && User.find_by(id: payload[:user_id], active: true)
      return user if user

      reject_unauthorized_connection
    end

    def token_from_request
      request.params[:token].presence
    end
  end
end
