module Admin
  module Users
    class Update
      Result = Struct.new(:success?, :user, :errors, keyword_init: true)

      def initialize(user:, role_name:, school:, params:)
        @user = user
        @role_name = role_name
        @school = school
        @params = params
      end

      def call
        User.transaction do
          user.update!(user_params)
          update_profile!
        end

        Result.new(success?: true, user: user, errors: [])
      rescue ActiveRecord::RecordInvalid => e
        Result.new(success?: false, user: user, errors: e.record.errors.full_messages)
      end

      private

      attr_reader :user, :role_name, :school, :params

      def user_params
        {
          email: params[:email].presence || user.email,
          first_name: params.key?(:first_name) ? params[:first_name] : user.first_name,
          last_name: params.key?(:last_name) ? params[:last_name] : user.last_name,
          locale: params[:locale].presence || user.locale
        }
      end

      def update_profile!
        if role_name == "teacher"
          profile = user.teacher_profile || user.build_teacher_profile(school: school)
          profile.update!(params.fetch(:teacher_profile, {}))
        else
          profile = user.student_profile || user.build_student_profile(school: school)
          profile.update!(params.fetch(:student_profile, {}))
        end
      end
    end
  end
end
