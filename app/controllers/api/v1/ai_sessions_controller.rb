module Api
  module V1
    class AiSessionsController < BaseController
      before_action :set_ai_session, only: %i[show update close]

      def index
        limit, offset = pagination_params
        sessions = current_user.ai_sessions.includes(:assignment, :subject, :submission).order(last_activity_at: :desc).limit(limit).offset(offset)
        sessions = sessions.where(school_id: current_school.id) if current_school

        render json: sessions.map { |session| serialize_session(session) }
      end

      def show
        return render_forbidden unless owns_session?(@ai_session)

        render json: serialize_session(@ai_session, include_messages: true)
      end

      def create
        school = current_school || current_user.schools.first
        return render_not_found unless school

        result = AiSessions::Start.new(user: current_user, school: school, params: ai_session_params.to_h.symbolize_keys).call
        if result.success?
          log_activity(action: "ai_session_started", trackable: result.session, metadata: { ai_session_id: result.session.id })
          render json: serialize_session(result.session), status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      def update
        return render_forbidden unless owns_session?(@ai_session)

        if @ai_session.update(ai_session_update_params.merge(last_activity_at: Time.current))
          render json: serialize_session(@ai_session.reload)
        else
          render json: { errors: @ai_session.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def close
        return render_forbidden unless owns_session?(@ai_session)

        result = AiSessions::Complete.new(session: @ai_session).call
        if result.success?
          log_activity(action: "ai_session_completed", trackable: @ai_session, metadata: { ai_session_id: @ai_session.id })
          render json: serialize_session(@ai_session.reload)
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def set_ai_session
        @ai_session = AiSession.includes(:ai_messages, :assignment, :subject, :submission).find_by(id: params[:id])
        render_not_found unless @ai_session
      end

      def owns_session?(session)
        current_user.has_role?("admin") || session.user_id == current_user.id
      end

      def ai_session_params
        params.permit(:assignment_id, :submission_id, :subject_id, :title, :session_type, :status, context_data: {})
      end

      def ai_session_update_params
        params.permit(:title, :status, :ended_at, context_data: {})
      end

      def serialize_session(session, include_messages: false)
        payload = {
          id: session.id,
          school_id: session.school_id,
          title: session.title,
          session_type: session.session_type,
          status: session.status,
          started_at: session.started_at,
          last_activity_at: session.last_activity_at,
          ended_at: session.ended_at,
          context_data: session.context_data,
          assignment_id: session.assignment_id,
          submission_id: session.submission_id,
          subject_id: session.subject_id
        }

        if include_messages
          payload[:messages] = session.ai_messages.map do |message|
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

        payload
      end
    end
  end
end
