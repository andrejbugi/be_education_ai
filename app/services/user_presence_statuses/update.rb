module UserPresenceStatuses
  class Update
    Result = Struct.new(:success?, :presence_status, :errors, keyword_init: true)

    def initialize(user:, params:)
      @user = user
      @params = params
    end

    def call
      presence_status = user.user_presence_status || user.build_user_presence_status
      presence_status.status = params[:status].presence || "online"
      presence_status.last_seen_at = Time.current
      presence_status.save!

      Result.new(success?: true, presence_status: presence_status, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, presence_status: e.record, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :user, :params
  end
end
