class DailyQuizAnswer < ApplicationRecord
  belongs_to :school
  belongs_to :student, class_name: "User"
  belongs_to :daily_quiz_question

  validates :quiz_date, :answered_at, presence: true
  validates :xp_awarded, numericality: { greater_than_or_equal_to: 0 }
  validates :student_id, uniqueness: { scope: %i[school_id quiz_date] }
  validate :validate_answer_presence
  validate :validate_question_scope

  private

  def validate_answer_presence
    return unless daily_quiz_question

    value = if daily_quiz_question.single_choice?
      selected_answer
    else
      answer_text
    end

    errors.add(:base, "Answer is required") if value.blank?
  end

  def validate_question_scope
    return unless daily_quiz_question

    if school_id.present? && daily_quiz_question.school_id.present? && daily_quiz_question.school_id != school_id
      errors.add(:daily_quiz_question, "does not belong to this school")
    end

    return if quiz_date.blank? || daily_quiz_question.quiz_date == quiz_date

    errors.add(:quiz_date, "must match the quiz question date")
  end
end
