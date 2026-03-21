module Api
  module V1
    module Admin
      class TeachersController < BaseController
        before_action :require_current_school!
        before_action :set_teacher, only: %i[show update resend_invitation deactivate assign_subjects assign_classrooms]

        def index
          teachers = scoped_teachers
          invitations = invitations_for(teachers, role_name: "teacher")

          render json: teachers.map do |teacher|
            serialize_admin_teacher(teacher, school: current_school, invitation: invitations[teacher.id])
          end
        end

        def create
          result = ::Admin::Users::Invite.new(
            admin: current_user,
            school: current_school,
            role_name: "teacher",
            params: teacher_create_params.to_h.deep_symbolize_keys
          ).call

          if result.success?
            render json: serialize_admin_teacher(result.user, school: current_school, invitation: result.invitation), status: :created
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        def show
          render json: serialize_admin_teacher(@teacher, school: current_school, invitation: invitation_for(@teacher, role_name: "teacher"))
        end

        def update
          result = ::Admin::Users::Update.new(
            user: @teacher,
            role_name: "teacher",
            school: current_school,
            params: teacher_update_params.to_h.deep_symbolize_keys
          ).call

          if result.success?
            render json: serialize_admin_teacher(result.user, school: current_school, invitation: invitation_for(result.user, role_name: "teacher"))
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        def resend_invitation
          invitation = UserInvitation.find_by(user: @teacher, school: current_school, role_name: "teacher")
          return render json: { errors: ["Invitation not found"] }, status: :unprocessable_entity unless invitation

          result = ::Admin::Invitations::Resend.new(invitation: invitation).call

          if result.success?
            render json: serialize_admin_teacher(@teacher, school: current_school, invitation: result.invitation)
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        def deactivate
          result = ::Admin::Users::SetActive.new(user: @teacher, active: false, school: current_school, role_name: "teacher").call

          if result.success?
            render json: serialize_admin_teacher(result.user, school: current_school, invitation: invitation_for(result.user, role_name: "teacher"))
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        def assign_subjects
          result = ::Admin::Memberships::Sync.new(
            user: @teacher,
            school: current_school,
            association: :teacher_subjects,
            ids: params[:subject_ids]
          ).call

          if result.success?
            render json: serialize_admin_teacher(@teacher.reload, school: current_school, invitation: invitation_for(@teacher, role_name: "teacher"))
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        def assign_classrooms
          result = ::Admin::Memberships::Sync.new(
            user: @teacher,
            school: current_school,
            association: :teacher_classrooms,
            ids: params[:classroom_ids]
          ).call

          if result.success?
            render json: serialize_admin_teacher(@teacher.reload, school: current_school, invitation: invitation_for(@teacher, role_name: "teacher"))
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        private

        def scoped_teachers
          relation = current_school.users.joins(:roles)
                           .where(roles: { name: "teacher" })
                           .includes(:teacher_profile, :roles, :subjects, :teaching_classrooms)
                           .distinct

          if params[:q].present?
            query = "%#{params[:q].strip}%"
            relation = relation.where("users.email ILIKE ? OR users.first_name ILIKE ? OR users.last_name ILIKE ?", query, query, query)
          end

          teachers = relation.order(:first_name, :last_name, :email).to_a
          teachers = teachers.select { |teacher| invitation_status_for(teacher, school: current_school, role_name: "teacher") == params[:invitation_status] } if params[:invitation_status].present?

          limit, offset = pagination_params
          teachers.drop(offset).first(limit)
        end

        def set_teacher
          @teacher = current_school.users.joins(:roles).where(roles: { name: "teacher" }).distinct.find_by(id: params[:id])
          render_not_found unless @teacher
        end

        def teacher_create_params
          params.permit(:email, :first_name, :last_name, :locale, teacher_profile: %i[title bio])
        end

        def teacher_update_params
          params.permit(:email, :first_name, :last_name, :locale, teacher_profile: %i[title bio])
        end

        def invitation_for(user, role_name:)
          UserInvitation.find_by(user: user, school: current_school, role_name: role_name)
        end

        def invitations_for(users, role_name:)
          UserInvitation.where(user_id: users.map(&:id), school_id: current_school.id, role_name: role_name).index_by(&:user_id)
        end
      end
    end
  end
end
