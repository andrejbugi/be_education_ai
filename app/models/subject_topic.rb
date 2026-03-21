class SubjectTopic < ApplicationRecord
  belongs_to :subject

  has_many :assignments, dependent: :nullify

  before_validation :normalize_name

  validates :name, presence: true, length: { maximum: 120 }, uniqueness: { scope: :subject_id }

  private

  def normalize_name
    self.name = name.to_s.strip.presence
  end
end
