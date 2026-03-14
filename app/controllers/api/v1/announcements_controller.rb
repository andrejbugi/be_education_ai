module Api
  module V1
    class AnnouncementsController < BaseController
      before_action :set_announcement, only: %i[show update publish archive]

      def index
        limit, offset = pagination_params
        announcements = scoped_announcements
        announcements = announcements.select { |announcement| can_view_announcement?(announcement) }
        announcements = announcements.sort_by { |announcement| [announcement.published_at || Time.at(0), announcement.created_at] }.reverse
        announcements = announcements.drop(offset).first(limit)

        render json: announcements.map { |announcement| serialize_announcement(announcement) }
      end

      def show
        return render_forbidden unless can_view_announcement?(@announcement)

        render json: serialize_announcement(@announcement, include_comments: true)
      end

      def create
        require_role!("teacher", "admin")
        return if performed?

        school = resolve_school
        return render_not_found unless school

        result = Announcements::Create.new(author: current_user, school: school, params: announcement_params.to_h.symbolize_keys).call
        if result.success?
          log_activity(action: "announcement_created", trackable: result.announcement, metadata: { announcement_id: result.announcement.id })
          render json: serialize_announcement(result.announcement), status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      def update
        require_role!("teacher", "admin")
        return if performed?
        return render_forbidden unless can_manage_announcement?(@announcement)

        if @announcement.update(announcement_params)
          render json: serialize_announcement(@announcement.reload)
        else
          render json: { errors: @announcement.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def publish
        require_role!("teacher", "admin")
        return if performed?
        return render_forbidden unless can_manage_announcement?(@announcement)

        result = Announcements::Publish.new(announcement: @announcement, actor: current_user).call
        if result.success?
          log_activity(action: "announcement_published", trackable: @announcement, metadata: { announcement_id: @announcement.id })
          render json: serialize_announcement(@announcement.reload)
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      def archive
        require_role!("teacher", "admin")
        return if performed?
        return render_forbidden unless can_manage_announcement?(@announcement)

        if @announcement.update(status: :archived)
          render json: serialize_announcement(@announcement.reload)
        else
          render json: { errors: @announcement.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_announcement
        @announcement = Announcement.includes(:school, :author, :classroom, :subject, comments: :author).find_by(id: params[:id])
        render_not_found unless @announcement
      end

      def scoped_announcements
        scope = Announcement.includes(:school, :author, :classroom, :subject)
        school = current_school
        scope = scope.where(school_id: school.id) if school

        scope.to_a
      end

      def can_manage_announcement?(announcement)
        current_user.has_role?("admin") || announcement.author_id == current_user.id
      end

      def can_view_announcement?(announcement)
        can_manage_announcement?(announcement) || (announcement.published? && announcement.visible_to?(current_user))
      end

      def resolve_school
        school = current_school
        school ||= current_user.schools.first if current_user.schools.one?
        school
      end

      def announcement_params
        params.permit(:classroom_id, :subject_id, :title, :body, :status, :published_at, :starts_at, :ends_at, :priority, :audience_type)
      end

      def serialize_announcement(announcement, include_comments: false)
        payload = {
          id: announcement.id,
          school_id: announcement.school_id,
          title: announcement.title,
          body: announcement.body,
          status: announcement.status,
          priority: announcement.priority,
          audience_type: announcement.audience_type,
          published_at: announcement.published_at,
          starts_at: announcement.starts_at,
          ends_at: announcement.ends_at,
          author: {
            id: announcement.author_id,
            full_name: announcement.author.full_name
          },
          classroom: announcement.classroom && { id: announcement.classroom_id, name: announcement.classroom.name },
          subject: announcement.subject && { id: announcement.subject_id, name: announcement.subject.name }
        }

        if include_comments
          payload[:comments] = announcement.comments.order(created_at: :asc).map do |comment|
            {
              id: comment.id,
              body: comment.body,
              author_name: comment.author.full_name,
              created_at: comment.created_at
            }
          end
        end

        payload
      end
    end
  end
end
