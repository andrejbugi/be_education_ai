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
        create_resources!(assignment)
      end

      Result.new(success?: true, assignment: assignment, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, assignment: e.record, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :teacher, :params

    def assignment_attributes
      params.except(:steps, :resources)
    end

    def step_params
      Array(params[:steps])
    end

    def resource_params
      Array(params[:resources])
    end

    def create_steps!(assignment)
      step_params.each_with_index do |step, index|
        step = step.with_indifferent_access
        assignment.assignment_steps.create!(
          position: step[:position].presence || (index + 1),
          title: step[:title],
          content: step[:content],
          prompt: step[:prompt],
          resource_url: step[:resource_url],
          example_answer: step[:example_answer],
          step_type: step[:step_type].presence || "text",
          required: step.key?(:required) ? step[:required] : true,
          metadata: step[:metadata] || {},
          content_json: step[:content_json] || []
        )
      end
    end

    def create_resources!(assignment)
      resource_params.each_with_index do |resource, index|
        resource = resource.with_indifferent_access
        assignment.assignment_resources.create!(
          title: resource[:title],
          resource_type: resource[:resource_type],
          file_url: resource[:file_url],
          external_url: resource[:external_url],
          embed_url: resource[:embed_url],
          description: resource[:description],
          position: resource[:position].presence || (index + 1),
          is_required: resource[:is_required] || false,
          metadata: resource[:metadata] || {}
        )
      end
    end
  end
end
