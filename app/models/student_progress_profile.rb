class StudentProgressProfile < ApplicationRecord
  LEVEL_XP_STEP = 100

  belongs_to :school
  belongs_to :student, class_name: "User"

  has_many :student_badges, dependent: :destroy

  validates :total_xp, :current_level, :current_streak, :longest_streak, numericality: { greater_than_or_equal_to: 0 }

  def current_level_start_xp
    (current_level - 1) * LEVEL_XP_STEP
  end

  def next_level_xp
    current_level * LEVEL_XP_STEP
  end

  def xp_to_next_level
    [next_level_xp - total_xp, 0].max
  end

  def level_progress_percent
    progress = total_xp - current_level_start_xp
    ((progress.to_d / LEVEL_XP_STEP) * 100).round(2).to_f.clamp(0, 100)
  end
end
