module Api
  module V1
    class CommentsController < BaseController
      COMMENTABLE_TYPES = {
        "Assignment" => Assignment,
        "Submission" => Submission,
        "Grade" => Grade,
        "CalendarEvent" => CalendarEvent
      }.freeze

      def index
        return render json: [] if params[:commentable_type].blank? || params[:commentable_id].blank?

        commentable = find_commentable
        return render_not_found unless commentable
        return render_forbidden unless can_access_commentable?(commentable)

        limit, offset = pagination_params
        comments = commentable.comments.includes(:author).order(created_at: :asc).limit(limit).offset(offset)
        render json: comments.map { |comment| serialize_comment(comment) }
      end

      def create
        commentable = find_commentable
        return render_not_found unless commentable
        return render_forbidden unless can_access_commentable?(commentable)

        comment = Comment.new(comment_params.merge(author: current_user, commentable: commentable))

        if comment.save
          log_activity(action: "comment_created", trackable: comment, metadata: { commentable_type: comment.commentable_type, commentable_id: comment.commentable_id })
          render json: serialize_comment(comment), status: :created
        else
          render json: { errors: comment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def find_commentable
        type = params[:commentable_type].to_s
        klass = COMMENTABLE_TYPES[type]
        return nil unless klass

        klass.find_by(id: params[:commentable_id])
      end

      def comment_params
        params.permit(:commentable_type, :commentable_id, :body, :visibility)
      end

      def serialize_comment(comment)
        {
          id: comment.id,
          body: comment.body,
          visibility: comment.visibility,
          commentable_type: comment.commentable_type,
          commentable_id: comment.commentable_id,
          author: {
            id: comment.author_id,
            full_name: comment.author.full_name
          },
          created_at: comment.created_at
        }
      end

      def can_access_commentable?(commentable)
        return true if current_user.has_role?("admin")

        case commentable
        when Assignment
          commentable.teacher_id == current_user.id || commentable.classroom.students.exists?(id: current_user.id)
        when Submission
          commentable.student_id == current_user.id || commentable.assignment.teacher_id == current_user.id
        when Grade
          commentable.submission.student_id == current_user.id || commentable.teacher_id == current_user.id
        when CalendarEvent
          current_user.schools.exists?(id: commentable.school_id)
        else
          false
        end
      end
    end
  end
end
