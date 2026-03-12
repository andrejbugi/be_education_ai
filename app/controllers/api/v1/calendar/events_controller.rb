module Api
  module V1
    module Calendar
      class EventsController < BaseController
        def index
          school = resolve_school
          return render_not_found unless school

          limit, offset = pagination_params
          events = school.calendar_events.order(:starts_at).limit(limit).offset(offset)
          render json: events.map { |event| serialize_event(event) }
        end

        def create
          require_role!("teacher", "admin")
          return if performed?

          school = resolve_school
          return render_not_found unless school

          event = school.calendar_events.new(event_params)
          if event.save
            attach_participants(event)
            log_activity(action: "calendar_event_created", trackable: event, metadata: { calendar_event_id: event.id })
            render json: serialize_event(event.reload), status: :created
          else
            render json: { errors: event.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          require_role!("teacher", "admin")
          return if performed?

          event = CalendarEvent.find_by(id: params[:id])
          return render_not_found unless event
          return render_forbidden unless current_user.schools.exists?(id: event.school_id)

          if event.update(event_params)
            attach_participants(event)
            render json: serialize_event(event.reload)
          else
            render json: { errors: event.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def resolve_school
          school = current_school
          school ||= current_user.schools.first if current_user.schools.one?
          school
        end

        def event_params
          params.permit(:assignment_id, :title, :description, :event_type, :starts_at, :ends_at, :all_day, metadata: {})
        end

        def participant_ids
          Array(params[:participant_ids]).map(&:to_i).uniq
        end

        def attach_participants(event)
          return if participant_ids.empty?

          valid_ids = event.school.users.where(id: participant_ids).pluck(:id)
          valid_ids.each do |user_id|
            event.event_participants.find_or_create_by!(user_id: user_id)
          end
        end

        def serialize_event(event)
          {
            id: event.id,
            school_id: event.school_id,
            assignment_id: event.assignment_id,
            title: event.title,
            description: event.description,
            event_type: event.event_type,
            starts_at: event.starts_at,
            ends_at: event.ends_at,
            all_day: event.all_day,
            metadata: event.metadata,
            participants: event.participants.select(:id, :first_name, :last_name, :email)
          }
        end
      end
    end
  end
end
