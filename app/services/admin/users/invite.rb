module Admin
  module Users
    class Invite
      Result = Struct.new(:success?, :user, :invitation, :raw_token, :errors, keyword_init: true)
      INVITATION_EXPIRY = 7.days

      def initialize(admin:, school:, role_name:, params:)
        @admin = admin
        @school = school
        @role_name = role_name
        @params = params
      end

      def call
        user = User.find_by(email: normalized_email)
        invitation = nil
        raw_token = SecureRandom.urlsafe_base64(32)
        new_user = user.nil?

        User.transaction do
          if new_user
            user = build_user
            user.save!
          end

          return Result.new(success?: false, user: user, invitation: nil, raw_token: nil, errors: ["User is already a member of this school"]) if already_member_of_school?(user)

          ensure_role!(user)
          ensure_school_membership!(user, new_user: new_user)
          create_profile!(user)

          invitation = create_or_refresh_invitation!(user, raw_token)
        end

        UserInvitationMailer.invitation_email(invitation.id, raw_token).deliver_now
        Result.new(success?: true, user: user, invitation: invitation, raw_token: raw_token, errors: [])
      rescue ActiveRecord::RecordInvalid => e
        Result.new(success?: false, user: user, invitation: invitation, raw_token: nil, errors: e.record.errors.full_messages)
      end

      private

      attr_reader :admin, :school, :role_name, :params

      def normalized_email
        params[:email].to_s.downcase.strip
      end

      def build_user
        random_password = SecureRandom.base58(24)

        User.new(
          email: normalized_email,
          first_name: params[:first_name],
          last_name: params[:last_name],
          locale: params[:locale].presence || "mk",
          active: false,
          password: random_password,
          password_confirmation: random_password
        )
      end

      def create_profile!(user)
        if role_name == "teacher"
          return if user.teacher_profile.present?

          teacher_profile_params = params.fetch(:teacher_profile, {})
          user.create_teacher_profile!(
            school: school,
            title: teacher_profile_params[:title],
            bio: teacher_profile_params[:bio],
            room_name: teacher_profile_params[:room_name],
            room_label: teacher_profile_params[:room_label]
          )
        else
          return if user.student_profile.present?

          student_profile_params = params.fetch(:student_profile, {})
          user.create_student_profile!(
            school: school,
            student_number: student_profile_params[:student_number],
            grade_level: student_profile_params[:grade_level],
            guardian_name: student_profile_params[:guardian_name],
            guardian_phone: student_profile_params[:guardian_phone]
          )
        end
      end

      def ensure_role!(user)
        UserRole.find_or_create_by!(user: user, role: Role.find_by!(name: role_name))
      end

      def ensure_school_membership!(user, new_user:)
        return if user.active? && !new_user

        SchoolUser.find_or_create_by!(school: school, user: user)
      end

      def create_or_refresh_invitation!(user, raw_token)
        invitation = UserInvitation.find_or_initialize_by(
          user: user,
          school: school,
          role_name: role_name
        )

        invitation.assign_attributes(
          invited_by: admin,
          status: :pending,
          token_digest: UserInvitation.digest(raw_token),
          expires_at: INVITATION_EXPIRY.from_now,
          accepted_at: nil,
          last_sent_at: Time.current
        )
        invitation.save!
        invitation
      end

      def already_member_of_school?(user)
        SchoolUser.exists?(school: school, user: user)
      end
    end
  end
end
