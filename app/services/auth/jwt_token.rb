module Auth
  class JwtToken
    ALGORITHM = "HS256".freeze

    def self.encode(payload, expires_at: 7.days.from_now)
      data = payload.deep_symbolize_keys
      data[:exp] = expires_at.to_i
      JWT.encode(data, secret_key, ALGORITHM)
    end

    def self.decode(token)
      decoded, = JWT.decode(token, secret_key, true, algorithm: ALGORITHM)
      decoded.with_indifferent_access
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end

    def self.secret_key
      Rails.application.credentials.jwt_secret || ENV.fetch("JWT_SECRET", nil) || Rails.application.secret_key_base
    end
  end
end
