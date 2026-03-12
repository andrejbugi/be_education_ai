class User < ApplicationRecord
  has_secure_password

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  has_many :school_users, dependent: :destroy
  has_many :schools, through: :school_users

  has_one :teacher_profile, dependent: :destroy
  has_one :student_profile, dependent: :destroy

  has_many :classroom_users, dependent: :destroy
  has_many :student_classrooms, through: :classroom_users, source: :classroom

  has_many :teacher_classrooms, class_name: "TeacherClassroom", dependent: :destroy
  has_many :teaching_classrooms, through: :teacher_classrooms, source: :classroom

  has_many :teacher_subjects, foreign_key: :teacher_id, dependent: :destroy
  has_many :subjects, through: :teacher_subjects

  has_many :assignments, foreign_key: :teacher_id, inverse_of: :teacher
  has_many :submissions, foreign_key: :student_id, dependent: :destroy
  has_many :grades, foreign_key: :teacher_id

  has_many :comments, foreign_key: :author_id, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :activity_logs, dependent: :destroy

  has_many :calendar_participations, class_name: "EventParticipant", dependent: :destroy
  has_many :calendar_events, through: :calendar_participations

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  before_validation :normalize_email

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

  private

  def normalize_email
    self.email = email.to_s.downcase.strip
  end
end
