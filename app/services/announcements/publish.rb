module Announcements
  class Publish
    Result = Struct.new(:success?, :announcement, :errors, keyword_init: true)

    def initialize(announcement:, actor:)
      @announcement = announcement
      @actor = actor
    end

    def call
      return Result.new(success?: false, announcement: announcement, errors: ["Announcement is already published"]) if announcement.published?

      Announcement.transaction do
        announcement.update!(status: :published, published_at: Time.current)
        notify_recipients
      end

      Result.new(success?: true, announcement: announcement, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, announcement: e.record, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :announcement, :actor

    def notify_recipients
      Announcements::DispatchNotifications.new(announcement: announcement, actor: actor).call
    end
  end
end
