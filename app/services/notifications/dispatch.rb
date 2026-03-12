module Notifications
  class Dispatch
    def initialize(user:, notification_type:, title:, body: nil, payload: {}, actor: nil)
      @user = user
      @notification_type = notification_type
      @title = title
      @body = body
      @payload = payload || {}
      @actor = actor
    end

    def call
      Notification.create!(
        user: user,
        actor: actor,
        notification_type: notification_type,
        title: title,
        body: body,
        payload: payload
      )
    end

    private

    attr_reader :user, :notification_type, :title, :body, :payload, :actor
  end
end
