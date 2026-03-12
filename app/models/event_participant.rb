class EventParticipant < ApplicationRecord
  belongs_to :calendar_event
  belongs_to :user

  validates :user_id, uniqueness: { scope: :calendar_event_id }
end
