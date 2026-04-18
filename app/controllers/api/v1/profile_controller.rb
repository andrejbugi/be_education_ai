module Api
  module V1
    class ProfileController < BaseController
      def show
        render json: {
          user: current_user.as_json(only: %i[id email first_name last_name locale active]),
          roles: current_user.roles.pluck(:name),
          teacher_profile: current_user.teacher_profile,
          student_profile: current_user.student_profile,
          accessibility: current_user.accessibility_settings
        }
      end

      def update
        User.transaction do
          current_user.update!(user_params)
          current_user.assign_accessibility_settings(accessibility_params) if accessibility_params.present?
          current_user.save! if accessibility_params.present?

          if current_user.has_role?("teacher")
            profile = current_user.teacher_profile || current_user.build_teacher_profile
            profile.update!(teacher_profile_params) if teacher_profile_params.present?
          end

          if current_user.has_role?("student")
            profile = current_user.student_profile || current_user.build_student_profile
            profile.update!(student_profile_params) if student_profile_params.present?
          end
        end

        render json: {
          user: current_user.reload.as_json(only: %i[id email first_name last_name locale active]),
          teacher_profile: current_user.teacher_profile,
          student_profile: current_user.student_profile,
          accessibility: current_user.accessibility_settings
        }
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      private

      def user_params
        params.permit(:first_name, :last_name, :locale)
      end

      def accessibility_params
        params.fetch(:accessibility, {}).permit(:font_scale, :contrast_mode, :reading_font, :reduce_motion)
      end

      def teacher_profile_params
        params.fetch(:teacher_profile, {}).permit(:school_id, :title, :bio, :room_name, :room_label)
      end

      def student_profile_params
        params.fetch(:student_profile, {}).permit(:school_id, :student_number, :grade_level, :guardian_name, :guardian_phone)
      end
    end
  end
end
