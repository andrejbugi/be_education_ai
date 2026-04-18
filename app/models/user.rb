class User < ApplicationRecord
  has_secure_password

  ACCESSIBILITY_DEFAULTS = {
    "font_scale" => "md",
    "contrast_mode" => "default",
    "reading_font" => "default",
    "reduce_motion" => false
  }.freeze
  ACCESSIBILITY_ALLOWED_VALUES = {
    "font_scale" => %w[sm md lg xl].freeze,
    "contrast_mode" => %w[default high].freeze,
    "reading_font" => %w[default dyslexic].freeze
  }.freeze

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  has_many :school_users, dependent: :destroy
  has_many :schools, through: :school_users
  has_many :auth_sessions, dependent: :destroy
  has_many :user_invitations, dependent: :destroy
  has_many :sent_user_invitations, class_name: "UserInvitation", foreign_key: :invited_by_id, dependent: :restrict_with_exception

  has_one :teacher_profile, dependent: :destroy
  has_one :student_profile, dependent: :destroy

  has_many :classroom_users, dependent: :destroy
  has_many :student_classrooms, through: :classroom_users, source: :classroom

  has_many :teacher_classrooms, class_name: "TeacherClassroom", dependent: :destroy
  has_many :teaching_classrooms, through: :teacher_classrooms, source: :classroom

  has_many :teacher_subjects, foreign_key: :teacher_id, dependent: :destroy
  has_many :subjects, through: :teacher_subjects

  has_many :weekly_schedule_slots, foreign_key: :teacher_id, dependent: :destroy
  has_many :assignments, foreign_key: :teacher_id, inverse_of: :teacher
  has_many :submissions, foreign_key: :student_id, dependent: :destroy
  has_many :grades, foreign_key: :teacher_id
  has_many :homeroom_assignments, foreign_key: :teacher_id, dependent: :destroy
  has_many :homeroom_classrooms, through: :homeroom_assignments, source: :classroom
  has_many :authored_announcements, foreign_key: :author_id, class_name: "Announcement", dependent: :destroy
  has_many :attendance_records, foreign_key: :student_id, dependent: :destroy
  has_many :recorded_attendance_records, foreign_key: :teacher_id, class_name: "AttendanceRecord", dependent: :destroy
  has_many :student_performance_snapshots, foreign_key: :student_id, dependent: :destroy
  has_many :student_progress_profiles, foreign_key: :student_id, dependent: :destroy
  has_many :student_badges, foreign_key: :student_id, dependent: :destroy
  has_many :daily_quiz_answers, foreign_key: :student_id, dependent: :destroy
  has_many :student_reward_events, foreign_key: :student_id, dependent: :destroy
  has_many :ai_sessions, dependent: :destroy
  has_many :created_daily_quiz_questions, class_name: "DailyQuizQuestion", foreign_key: :created_by_id, dependent: :nullify
  has_many :created_conversations, class_name: "Conversation", foreign_key: :created_by_id
  has_many :conversation_participants, dependent: :destroy
  has_many :conversations, through: :conversation_participants
  has_many :sent_messages, class_name: "Message", foreign_key: :sender_id, dependent: :destroy
  has_many :message_reactions, dependent: :destroy
  has_many :message_deliveries, dependent: :destroy
  has_many :message_reads, dependent: :destroy
  has_one :user_presence_status, dependent: :destroy
  has_many :created_discussion_spaces, class_name: "DiscussionSpace", foreign_key: :created_by_id, dependent: :destroy
  has_many :discussion_threads, foreign_key: :creator_id, dependent: :destroy
  has_many :discussion_posts, foreign_key: :author_id, dependent: :destroy

  has_many :comments, foreign_key: :author_id, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :activity_logs, dependent: :destroy

  has_many :calendar_participations, class_name: "EventParticipant", dependent: :destroy
  has_many :calendar_events, through: :calendar_participations

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  before_validation :normalize_settings
  before_validation :normalize_email

  validate :validate_accessibility_settings

  def has_role?(role_name)
    roles.any? { |role| role.name == role_name.to_s }
  end

  def has_any_role?(*role_names)
    allowed = role_names.flatten.map(&:to_s)
    roles.any? { |role| allowed.include?(role.name) }
  end

  def full_name
    [first_name, last_name].compact.join(" ").strip.presence || email
  end

  def accessibility_settings
    stored_settings = settings.is_a?(Hash) ? settings : {}
    stored_accessibility = stored_settings.fetch("accessibility", {})

    ACCESSIBILITY_DEFAULTS.merge(stored_accessibility.is_a?(Hash) ? stored_accessibility : {})
  end

  def assign_accessibility_settings(attributes)
    incoming = attributes.respond_to?(:to_h) ? attributes.to_h : {}
    normalized = incoming.deep_stringify_keys.slice(*ACCESSIBILITY_DEFAULTS.keys)

    self.settings = normalized_settings.merge(
      "accessibility" => accessibility_settings.merge(normalized)
    )
  end

  private

  def normalize_settings
    self.settings = normalized_settings
  end

  def normalize_email
    self.email = email.to_s.downcase.strip
  end

  def normalized_settings
    settings.is_a?(Hash) ? settings.deep_stringify_keys : {}
  end

  def validate_accessibility_settings
    accessibility = normalized_settings["accessibility"]
    return if accessibility.blank?

    unless accessibility.is_a?(Hash)
      errors.add(:settings, "accessibility must be an object")
      return
    end

    unsupported_keys = accessibility.keys - ACCESSIBILITY_DEFAULTS.keys
    if unsupported_keys.any?
      errors.add(:settings, "accessibility contains unsupported keys: #{unsupported_keys.sort.join(', ')}")
    end

    ACCESSIBILITY_ALLOWED_VALUES.each do |key, allowed_values|
      next if accessibility[key].blank?
      next if allowed_values.include?(accessibility[key])

      errors.add(:settings, "accessibility #{key} is invalid")
    end

    return if accessibility["reduce_motion"].in?([true, false, nil])

    errors.add(:settings, "accessibility reduce_motion must be true or false")
  end
end
