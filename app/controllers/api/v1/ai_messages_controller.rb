module Api
  module V1
    class AiMessagesController < BaseController
      MAX_STUDENT_QUESTION_LENGTH = 100

      before_action :set_ai_session

      def index
        return render_forbidden unless owns_session?(@ai_session)

        limit, offset = pagination_params

        render json: @ai_session.ai_messages.limit(limit).offset(offset).map do |message|
          {
            id: message.id,
            role: message.role,
            message_type: message.message_type,
            content: message.content,
            sequence_number: message.sequence_number,
            metadata: message.metadata,
            created_at: message.created_at
          }
        end
      end

      def create
        return render_forbidden unless owns_session?(@ai_session)

        message_params = enriched_ai_message_params
        if limit_reached_for?(message_params)
          return render json: question_limit_payload(message_params[:metadata]["assignment_step_id"]), status: :too_many_requests
        end

        if question_too_long?(message_params)
          return render json: question_length_payload, status: :unprocessable_entity
        end

        result = AiMessages::Append.new(ai_session: @ai_session, params: message_params).call
        if result.success?
          assistant_result = generate_tutor_response_for(result.message)
          log_activity(
            action: "ai_message_appended",
            trackable: @ai_session,
            metadata: {
              ai_session_id: @ai_session.id,
              ai_message_id: result.message.id,
              assistant_message_id: assistant_result&.message&.id
            }.compact
          )
          render json: {
            user_message: serialize_message(result.message),
            assistant_message: assistant_result&.message ? serialize_message(assistant_result.message) : nil
          }, status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def set_ai_session
        @ai_session = AiSession.find_by(id: params[:ai_session_id])
        render_not_found unless @ai_session
      end

      def owns_session?(session)
        current_user.has_role?("admin") || session.user_id == current_user.id
      end

      def ai_message_params
        message_param_source.permit(:role, :message_type, :content, metadata: {})
      end

      def message_param_source
        return params.require(:ai_message) if params[:ai_message].is_a?(ActionController::Parameters)

        ActionController::Parameters.new(
          params.to_unsafe_h.slice("role", "message_type", "content", "metadata")
        )
      end

      def enriched_ai_message_params
        permitted = ai_message_params.to_h.deep_symbolize_keys
        return permitted unless permitted[:role].to_s == "user" && permitted[:message_type].to_s == "question"

        assignment_step = resolved_assignment_step_for(permitted)
        return permitted unless assignment_step

        metadata = (permitted[:metadata] || {}).deep_stringify_keys
        metadata["assignment_step_id"] ||= assignment_step.id
        permitted.merge(metadata: metadata)
      end

      def limit_reached_for?(message_params)
        return false unless current_user.has_role?("student")
        return false unless message_params[:role].to_s == "user" && message_params[:message_type].to_s == "question"

        assignment_step = resolved_assignment_step_for(message_params)
        return false unless assignment_step

        !AiTutor::QuestionLimit.new(ai_session: @ai_session, assignment_step: assignment_step).allowed?
      end

      def question_limit_payload(assignment_step_id)
        {
          error: "AI question limit reached for this step",
          code: "step_question_limit_reached",
          assignment_step_id: assignment_step_id.to_i,
          limit: AiTutor::QuestionLimit::MAX_QUESTIONS_PER_STEP
        }
      end

      def question_too_long?(message_params)
        return false unless current_user.has_role?("student")
        return false unless message_params[:role].to_s == "user" && message_params[:message_type].to_s == "question"

        message_params[:content].to_s.strip.length > MAX_STUDENT_QUESTION_LENGTH
      end

      def question_length_payload
        {
          error: "AI question is too long",
          code: "ai_question_too_long",
          max_length: MAX_STUDENT_QUESTION_LENGTH
        }
      end

      def generate_tutor_response_for(message)
        return unless message.user? && message.question?

        result = AiTutor::GenerateResponse.new(ai_session: @ai_session, user_message: message).call
        return result if result.success?

        nil
      end

      def serialize_message(message)
        {
          id: message.id,
          role: message.role,
          message_type: message.message_type,
          content: message.content,
          sequence_number: message.sequence_number,
          metadata: message.metadata,
          created_at: message.created_at
        }
      end

      def resolved_assignment_step_for(message_params)
        metadata = message_params[:metadata] || {}
        requested_assignment_step_id = metadata[:assignment_step_id] || metadata["assignment_step_id"]

        AiTutor::ResolveAssignmentStep.new(
          ai_session: @ai_session,
          requested_assignment_step_id: requested_assignment_step_id
        ).call
      end
    end
  end
end
