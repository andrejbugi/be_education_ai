module Conversations
  class Create
    Result = Struct.new(:success?, :conversation, :errors, :created, keyword_init: true)

    def initialize(current_user:, school:, params:)
      @current_user = current_user
      @school = school
      @params = params
    end

    def call
      return failure(["School must be selected"]) unless school
      return failure(["Only direct conversations are enabled right now"]) unless conversation_type == "direct"

      target_user = resolved_target_user
      return failure(["A single participant must be selected"]) unless target_user
      return failure(["You cannot start a conversation with yourself"]) if target_user.id == current_user.id
      return failure(["Selected user must belong to the same school"]) unless target_user_in_school?(target_user)
      return failure(["This conversation is not allowed"]) unless allowed_direct_conversation?(target_user)

      existing = existing_direct_conversation(target_user)
      return Result.new(success?: true, conversation: existing, errors: [], created: false) if existing

      conversation = nil

      Conversation.transaction do
        conversation = school.conversations.create!(
          conversation_type: conversation_type,
          created_by: current_user,
          active: true
        )

        [current_user, target_user].each do |user|
          conversation.conversation_participants.create!(
            user: user,
            joined_at: Time.current,
            active: true
          )
        end
      end

      Result.new(success?: true, conversation: conversation, errors: [], created: true)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :current_user, :school, :params

    def conversation_type
      params[:conversation_type].presence || "direct"
    end

    def participant_ids
      Array(params[:participant_ids]).map(&:to_i).uniq - [0]
    end

    def resolved_target_user
      ids = participant_ids - [current_user.id]
      return nil unless ids.one?

      User.find_by(id: ids.first, active: true)
    end

    def target_user_in_school?(target_user)
      school.users.exists?(id: target_user.id)
    end

    def allowed_direct_conversation?(target_user)
      return true if current_user.has_role?("admin") || target_user.has_role?("admin")
      return true if teacher_teacher_pair?(target_user)
      return teacher_student_pair_with_shared_classroom?(target_user) if teacher_student_pair?(target_user)

      false
    end

    def teacher_teacher_pair?(target_user)
      current_user.has_role?("teacher") && target_user.has_role?("teacher")
    end

    def teacher_student_pair?(target_user)
      (current_user.has_role?("teacher") && target_user.has_role?("student")) ||
        (current_user.has_role?("student") && target_user.has_role?("teacher"))
    end

    def teacher_student_pair_with_shared_classroom?(target_user)
      teacher = current_user.has_role?("teacher") ? current_user : target_user
      student = current_user.has_role?("student") ? current_user : target_user

      teacher.teaching_classrooms.where(id: student.student_classrooms.select(:id)).exists?
    end

    def existing_direct_conversation(target_user)
      participant_ids = [current_user.id, target_user.id].sort

      Conversation.active.direct.where(school: school).includes(:active_conversation_participants).detect do |conversation|
        conversation.active_conversation_participants.map(&:user_id).sort == participant_ids
      end
    end

    def failure(errors)
      Result.new(success?: false, conversation: nil, errors: Array(errors), created: false)
    end
  end
end
