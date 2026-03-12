class CalendarEvent < ApplicationRecord
  belongs_to :school
  belongs_to :assignment, optional: true

  has_many :event_participants, dependent: :destroy
  has_many :participants, through: :event_participants, source: :user
  has_many :comments, as: :commentable, dependent: :destroy

  validates :title, :starts_at, presence: true
end
