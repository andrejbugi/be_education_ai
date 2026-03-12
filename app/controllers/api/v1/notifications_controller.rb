module Api
  module V1
    class NotificationsController < BaseController
      def index
        limit, offset = pagination_params
        notifications = current_user.notifications.order(created_at: :desc).limit(limit).offset(offset)

        render json: {
          unread_count: current_user.notifications.unread.count,
          items: notifications.map { |notification| serialize_notification(notification) }
        }
      end

      def mark_as_read
        notification = current_user.notifications.find_by(id: params[:id])
        return render_not_found unless notification

        notification.mark_as_read!
        render json: serialize_notification(notification)
      end

      private

      def serialize_notification(notification)
        {
          id: notification.id,
          notification_type: notification.notification_type,
          title: notification.title,
          body: notification.body,
          payload: notification.payload,
          read_at: notification.read_at,
          created_at: notification.created_at
        }
      end
    end
  end
end
