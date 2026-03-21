module Admin
  module Users
    class SetActive
      Result = Struct.new(:success?, :user, :errors, keyword_init: true)

      def initialize(user:, active:, school:, role_name:)
        @user = user
        @active = active
        @school = school
        @role_name = role_name
      end

      def call
        return reactivate_user if active

        User.transaction do
          revoke_school_invitation!
          remove_school_membership!
          remove_school_assignments!
          user.update!(active: false) unless user.school_users.exists?
        end

        Result.new(success?: true, user: user, errors: [])
      rescue ActiveRecord::RecordInvalid => e
        Result.new(success?: false, user: user, errors: e.record.errors.full_messages)
      end

      private

      attr_reader :user, :active, :school, :role_name

      def reactivate_user
        user.update!(active: true)
        Result.new(success?: true, user: user, errors: [])
      rescue ActiveRecord::RecordInvalid => e
        Result.new(success?: false, user: user, errors: e.record.errors.full_messages)
      end

      def revoke_school_invitation!
        invitation = UserInvitation.find_by(user: user, school: school, role_name: role_name)
        invitation.update!(status: :revoked) if invitation
      end

      def remove_school_membership!
        SchoolUser.where(user: user, school: school).delete_all
      end

      def remove_school_assignments!
        if role_name == "teacher"
          subject_ids = school.subjects.select(:id)
          classroom_ids = school.classrooms.select(:id)

          user.teacher_subjects.where(subject_id: subject_ids).delete_all
          user.teacher_classrooms.where(classroom_id: classroom_ids).delete_all
          user.homeroom_assignments.where(school_id: school.id).delete_all
        else
          classroom_ids = school.classrooms.select(:id)
          user.classroom_users.where(classroom_id: classroom_ids).delete_all
        end
      end
    end
  end
end
