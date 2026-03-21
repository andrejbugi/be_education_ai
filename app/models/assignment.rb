class Assignment < ApplicationRecord
  belongs_to :subject
  belongs_to :subject_topic, optional: true
  belongs_to :classroom
  belongs_to :teacher, class_name: "User"

  has_many :assignment_steps, -> { order(:position) }, dependent: :destroy
  has_many :assignment_resources, -> { order(:position) }, dependent: :destroy
  has_many :submissions, dependent: :destroy
  has_many :calendar_events, dependent: :nullify
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :ai_sessions, dependent: :nullify
  has_many :discussion_spaces, dependent: :destroy

  enum :status, {
    draft: 0,
    published: 1,
    scheduled: 2,
    closed: 3,
    archived: 4
  }

  validates :title, presence: true
  validates :assignment_type, presence: true
  validate :subject_topic_matches_subject

  scope :for_school, ->(school_id) { joins(:classroom).where(classrooms: { school_id: school_id }) }

  private

  def subject_topic_matches_subject
    return unless subject_topic
    return if subject_topic.subject_id == subject_id

    errors.add(:subject_topic_id, "must belong to the selected subject")
  end
end
