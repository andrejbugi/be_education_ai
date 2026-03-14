class AssignmentResource < ApplicationRecord
  RESOURCE_TYPES = %w[pdf file image video link text embed].freeze

  belongs_to :assignment

  validates :title, :resource_type, presence: true
  validates :resource_type, inclusion: { in: RESOURCE_TYPES }
  validates :position, uniqueness: { scope: :assignment_id }
end
