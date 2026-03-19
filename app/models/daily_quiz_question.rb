class DailyQuizQuestion < ApplicationRecord
  CATEGORIES = %w[geography history].freeze
  ANSWER_TYPES = %w[single_choice text].freeze

  belongs_to :school, optional: true
  belongs_to :created_by, class_name: "User", optional: true

  has_many :daily_quiz_answers, dependent: :restrict_with_exception

  validates :quiz_date, :title, :body, :category, :answer_type, :correct_answer, presence: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :answer_type, inclusion: { in: ANSWER_TYPES }
  validate :validate_unique_active_question, if: :is_active?
  validate :validate_answer_options_for_single_choice

  scope :active, -> { where(is_active: true) }
  scope :for_quiz_date, ->(quiz_date) { where(quiz_date: quiz_date) }

  def single_choice?
    answer_type == "single_choice"
  end

  private

  def validate_unique_active_question
    relation = self.class.active.where(quiz_date: quiz_date, school_id: school_id)
    relation = relation.where.not(id: id) if persisted?
    return unless relation.exists?

    errors.add(:quiz_date, "already has an active quiz question for this school scope")
  end

  def validate_answer_options_for_single_choice
    return unless single_choice?

    options = Array(answer_options).map(&:to_s).map(&:strip).reject(&:blank?)
    if options.empty?
      errors.add(:answer_options, "must include options for single choice quizzes")
      return
    end

    return if options.include?(correct_answer.to_s.strip)

    errors.add(:correct_answer, "must match one of the answer options")
  end
end
