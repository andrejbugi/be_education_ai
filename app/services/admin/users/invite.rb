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
        return Result.new(success?: false, user: nil, invitation: nil, raw_token: nil, errors: ["Email has already been taken"]) if User.exists?(email: normalized_email)

        user = nil
        invitation = nil
        raw_token = SecureRandom.urlsafe_base64(32)

        User.transaction do
          user = build_user
          user.save!

          UserRole.create!(user: user, role: Role.find_by!(name: role_name))
          SchoolUser.create!(school: school, user: user)
          create_profile!(user)

          invitation = UserInvitation.create!(
            user: user,
            school: school,
            invited_by: admin,
            role_name: role_name,
            status: :pending,
            token_digest: UserInvitation.digest(raw_token),
            expires_at: INVITATION_EXPIRY.from_now,
            last_sent_at: Time.current
          )
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
          teacher_profile_params = params.fetch(:teacher_profile, {})
          user.create_teacher_profile!(
            school: school,
            title: teacher_profile_params[:title],
            bio: teacher_profile_params[:bio]
          )
        else
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
    end
  end
end
