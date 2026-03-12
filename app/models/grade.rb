class Grade < ApplicationRecord
  belongs_to :submission
  belongs_to :teacher, class_name: "User"

  has_many :comments, as: :commentable, dependent: :destroy

  validates :score, numericality: { greater_than_or_equal_to: 0 }
  validates :graded_at, presence: true
end
