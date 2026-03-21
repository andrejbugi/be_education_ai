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
        User.transaction do
          user.update!(active: active)

          if !active
            invitation = UserInvitation.find_by(user: user, school: school, role_name: role_name)
            invitation.update!(status: :revoked) if invitation&.pending?
          end
        end

        Result.new(success?: true, user: user, errors: [])
      rescue ActiveRecord::RecordInvalid => e
        Result.new(success?: false, user: user, errors: e.record.errors.full_messages)
      end

      private

      attr_reader :user, :active, :school, :role_name
    end
  end
end
