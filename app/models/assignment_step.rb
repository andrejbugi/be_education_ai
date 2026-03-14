class AssignmentStep < ApplicationRecord
  EVALUATION_MODES = %w[manual normalized_text numeric regex].freeze

  belongs_to :assignment

  has_many :assignment_step_answer_keys, -> { order(:position) }, dependent: :destroy
  has_many :submission_step_answers, dependent: :destroy

  validates :position, presence: true, uniqueness: { scope: :assignment_id }
  validates :evaluation_mode, inclusion: { in: EVALUATION_MODES }

  def auto_check_enabled?
    evaluation_mode != "manual"
  end
end
