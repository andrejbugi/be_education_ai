require "bigdecimal"

module Submissions
  class EvaluateStepAnswer
    Result = Struct.new(:status, keyword_init: true)

    OPERATOR_PATTERN = /\s*([=+\-*\/^(),:])\s*/

    def initialize(assignment_step:, answer_text: nil, answer_data: {})
      @assignment_step = assignment_step
      @answer_text = answer_text
      @answer_data = answer_data || {}
    end

    def call
      return Result.new(status: :answered) unless assignment_step.auto_check_enabled?
      return Result.new(status: :answered) if submitted_value.blank?
      return Result.new(status: :answered) if answer_keys.empty?

      matched = answer_keys.any? { |answer_key| matches_answer_key?(answer_key) }
      Result.new(status: matched ? :correct : :incorrect)
    end

    private

    attr_reader :assignment_step, :answer_text, :answer_data

    def answer_keys
      assignment_step.assignment_step_answer_keys
    end

    def submitted_value
      answer_text.presence || answer_data[:value].presence || answer_data["value"].presence
    end

    def matches_answer_key?(answer_key)
      case assignment_step.evaluation_mode
      when "normalized_text"
        normalized_text_match?(answer_key)
      when "numeric"
        numeric_match?(answer_key)
      when "regex"
        regex_match?(answer_key)
      else
        false
      end
    end

    def normalized_text_match?(answer_key)
      normalize_text(submitted_value, case_sensitive: answer_key.case_sensitive) ==
        normalize_text(answer_key.value, case_sensitive: answer_key.case_sensitive)
    end

    def numeric_match?(answer_key)
      submitted_number = parse_decimal(submitted_value)
      key_number = parse_decimal(answer_key.value)
      return false if submitted_number.nil? || key_number.nil?

      tolerance = answer_key.tolerance || 0
      (submitted_number - key_number).abs <= tolerance
    end

    def regex_match?(answer_key)
      flags = answer_key.case_sensitive ? nil : Regexp::IGNORECASE
      Regexp.new(answer_key.value, flags).match?(submitted_value.to_s.strip)
    rescue RegexpError
      false
    end

    def normalize_text(value, case_sensitive:)
      normalized = value.to_s.strip
      normalized = normalized.downcase unless case_sensitive
      normalized = normalized.gsub(/\s+/, " ")
      normalized.gsub(OPERATOR_PATTERN, "\\1").strip
    end

    def parse_decimal(value)
      BigDecimal(value.to_s.strip)
    rescue ArgumentError
      nil
    end
  end
end
