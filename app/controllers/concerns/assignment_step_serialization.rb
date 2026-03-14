module AssignmentStepSerialization
  private

  def serialize_assignment_step(step, include_answer_keys: false)
    payload = {
      id: step.id,
      assignment_id: step.assignment_id,
      position: step.position,
      title: step.title,
      content: step.content,
      prompt: step.prompt,
      resource_url: step.resource_url,
      example_answer: step.example_answer,
      step_type: step.step_type,
      required: step.required,
      metadata: step.metadata,
      content_json: step.content_json,
      evaluation_mode: step.evaluation_mode
    }

    if include_answer_keys
      payload[:answer_keys] = step.assignment_step_answer_keys.map do |answer_key|
        {
          id: answer_key.id,
          value: answer_key.value,
          position: answer_key.position,
          tolerance: answer_key.tolerance&.to_f,
          case_sensitive: answer_key.case_sensitive,
          metadata: answer_key.metadata
        }
      end
    end

    payload
  end
end
