module Assignments
  class Create
    Result = Struct.new(:success?, :assignment, :errors, keyword_init: true)

    def initialize(teacher:, params:)
      @teacher = teacher
      @params = params
    end

    def call
      assignment = Assignment.new(assignment_attributes.merge(teacher: teacher))

      Assignment.transaction do
        assignment.save!
        create_steps!(assignment)
      end

      Result.new(success?: true, assignment: assignment, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, assignment: e.record, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :teacher, :params

    def assignment_attributes
      params.except(:steps)
    end

    def step_params
      Array(params[:steps])
    end

    def create_steps!(assignment)
      step_params.each_with_index do |step, index|
        step = step.with_indifferent_access
        assignment.assignment_steps.create!(
          position: step[:position].presence || (index + 1),
          title: step[:title],
          content: step[:content],
          step_type: step[:step_type].presence || "text",
          required: step.key?(:required) ? step[:required] : true,
          metadata: step[:metadata] || {}
        )
      end
    end
  end
end
