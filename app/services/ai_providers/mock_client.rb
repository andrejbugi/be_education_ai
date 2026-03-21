module AiProviders
  class MockClient < BaseClient
    ANSWER_SEEKING_PATTERNS = [
      /give me the answer/i,
      /\banswer\b/i,
      /\bsolution\b/i,
      /кажи ми го одговорот/i,
      /дај ми го одговорот/i,
      /реши ја задачата/i,
      /решението/i
    ].freeze
    STARTING_PATTERNS = [
      /how do i start/i,
      /where do i start/i,
      /how should i begin/i,
      /како да почнам/i,
      /од каде да почнам/i,
      /како да почнам да решавам/i
    ].freeze
    FEEDBACK_PATTERNS = [
      /does this sound okay/i,
      /is this okay/i,
      /is this good/i,
      /дали ова звучи океј/i,
      /дали звучи океј/i,
      /дали е добро/i,
      /дали е во ред/i,
      /дали ова е точно/i,
      /ова добро ли е/i
    ].freeze

    def generate_tutor_response(prompt:)
      Response.new(
        content: build_content(prompt),
        metadata: {
          "provider" => "mock",
          "strategy" => strategy_for(prompt),
          "assignment_step_id" => prompt.dig(:assignment_step, :id)
        }.compact
      )
    end

    private

    def build_content(prompt)
      question = prompt[:student_question].to_s
      step = prompt[:assignment_step] || {}
      step_answer = prompt[:submission_step_answer] || {}
      step_label = current_step_label(step)

      return answer_boundary_message(step_label) if matches_any?(question, ANSWER_SEEKING_PATTERNS)
      return draft_feedback_message(question, step_label) if matches_any?(question, FEEDBACK_PATTERNS)
      return incorrect_answer_message(step_label, step_answer) if step_answer[:status] == "incorrect"
      return correct_answer_message(step_label) if step_answer[:status] == "correct"
      return starting_message(step) if matches_any?(question, STARTING_PATTERNS)
      return contextual_hint(step_label, question) if step_label.present?

      generic_message
    end

    def strategy_for(prompt)
      question = prompt[:student_question].to_s
      step_answer = prompt[:submission_step_answer] || {}

      return "boundary" if matches_any?(question, ANSWER_SEEKING_PATTERNS)
      return "draft_feedback" if matches_any?(question, FEEDBACK_PATTERNS)
      return "feedback" if step_answer[:status] == "incorrect"
      return "reinforcement" if step_answer[:status] == "correct"
      return "starting_hint" if matches_any?(question, STARTING_PATTERNS)

      "generic_hint"
    end

    def matches_any?(question, patterns)
      patterns.any? { |pattern| question.match?(pattern) }
    end

    def current_step_label(step)
      [
        step[:title].presence,
        step[:prompt].presence,
        step[:content].presence
      ].compact.first
    end

    def answer_boundary_message(step_label)
      if step_label.present?
        "Ќе ти помогнам со насока, но нема да го дадам конечниот одговор. Фокусирај се на: #{step_label}. Кој е првиот мал чекор што можеш да го направиш?"
      else
        "Ќе ти помогнам со насока, но нема да го дадам конечниот одговор. Кажи ми што проба досега и каде точно заглави."
      end
    end

    def incorrect_answer_message(step_label, step_answer)
      if step_answer[:answer_text].present?
        "Блиску си. Провери го последниот обид и спореди го со барањето#{step_label.present? ? " за #{step_label}" : ""}. Кој дел мислиш дека треба да се поправи?"
      else
        "Блиску си. Провери дали одговорот навистина го следи чекорот#{step_label.present? ? " #{step_label}" : ""}. Што би сменил прво?"
      end
    end

    def correct_answer_message(step_label)
      if step_label.present?
        "Ова изгледа добро за #{step_label}. Објасни ми со една реченица зошто мислиш дека чекорот е точен."
      else
        "Ова изгледа добро. Објасни ми со една реченица како стигна до тој одговор."
      end
    end

    def draft_feedback_message(question, step_label)
      extracted_attempt = extract_attempt(question)

      if extracted_attempt.present?
        "Да, ова звучи прилично добро#{step_label.present? ? " за #{step_label}" : ""}. Особено е добро што веќе го кажуваш значењето со свои зборови. За да биде попрецизно, пробај наместо \"многу ги сакаме\" да кажеш и каква врска има семејството, на пример: \"семејство се луѓе што се во роднинска врска и живеат или се чувствуваат блиски\"."
      else
        "Да, звучи блиску до добро. Сега направи го малку попрецизно: задржи ја главната идеја и додај што точно значи поимот, без да го повториш прашањето."
      end
    end

    def starting_message(step)
      prompt_text = step[:prompt].presence || step[:content].presence || step[:title].presence

      if prompt_text.present?
        "Почни од тековниот чекор: #{prompt_text}. Раздели го на една мала акција и кажи ми што би направил прво."
      else
        "Почни со тоа што ќе ја прочиташ задачата и ќе ја разделиш на мали чекори. Што точно се бара во првиот чекор?"
      end
    end

    def contextual_hint(step_label, question)
      if question.present?
        "Да одиме чекор по чекор#{step_label.present? ? " за #{step_label}" : ""}. Од твоето прашање, кој дел ти е најнејасен: условот, пресметката или објаснувањето?"
      else
        generic_message
      end
    end

    def generic_message
      "Тука сум да помогнам чекор по чекор. Кажи ми што точно ти е нејасно и што проба досега."
    end

    def extract_attempt(question)
      cleaned = question.to_s.strip
      attempt = cleaned.split(/дали|is this|does this/i).first.to_s.strip
      attempt = attempt.sub(/\A[^:.-]*[:.-]\s*/, "")
      attempt.presence
    end
  end
end
