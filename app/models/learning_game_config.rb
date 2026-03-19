class LearningGameConfig < ApplicationRecord
  belongs_to :school, optional: true

  validates :game_key, :title, presence: true
  validates :game_key, uniqueness: { scope: :school_id }
  validates :position, numericality: { greater_than_or_equal_to: 0 }
end
