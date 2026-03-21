module Api
  module V1
    module Admin
      class StudentsController < BaseController
        before_action :require_current_school!
        before_action :set_student, only: %i[show update resend_invitation deactivate assign_classrooms]

        def index
          students = scoped_students
          invitations = invitations_for(students, role_name: "student")

          render json: students.map do |student|
            serialize_admin_student(student, school: current_school, invitation: invitations[student.id])
          end
        end

        def create
          result = ::Admin::Users::Invite.new(
            admin: current_user,
            school: current_school,
            role_name: "student",
            params: student_create_params.to_h.deep_symbolize_keys
          ).call

          if result.success?
            render json: serialize_admin_student(result.user, school: current_school, invitation: result.invitation), status: :created
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        def show
          render json: serialize_admin_student(@student, school: current_school, invitation: invitation_for(@student, role_name: "student"))
        end

        def update
          result = ::Admin::Users::Update.new(
            user: @student,
            role_name: "student",
            school: current_school,
            params: student_update_params.to_h.deep_symbolize_keys
          ).call

          if result.success?
            render json: serialize_admin_student(result.user, school: current_school, invitation: invitation_for(result.user, role_name: "student"))
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        def resend_invitation
          invitation = UserInvitation.find_by(user: @student, school: current_school, role_name: "student")
          return render json: { errors: ["Invitation not found"] }, status: :unprocessable_entity unless invitation

          result = ::Admin::Invitations::Resend.new(invitation: invitation).call

          if result.success?
            render json: serialize_admin_student(@student, school: current_school, invitation: result.invitation)
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        def deactivate
          result = ::Admin::Users::SetActive.new(user: @student, active: false, school: current_school, role_name: "student").call

          if result.success?
            render json: serialize_admin_student(result.user, school: current_school, invitation: invitation_for(result.user, role_name: "student"))
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        def assign_classrooms
          result = ::Admin::Memberships::Sync.new(
            user: @student,
            school: current_school,
            association: :student_classrooms,
            ids: params[:classroom_ids]
          ).call

          if result.success?
            render json: serialize_admin_student(@student.reload, school: current_school, invitation: invitation_for(@student, role_name: "student"))
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        private

        def scoped_students
          relation = current_school.users.joins(:roles)
                           .where(roles: { name: "student" })
                           .includes(:student_profile, :roles, :student_classrooms)
                           .distinct

          if params[:q].present?
            query = "%#{params[:q].strip}%"
            relation = relation.where("users.email ILIKE ? OR users.first_name ILIKE ? OR users.last_name ILIKE ?", query, query, query)
          end

          students = relation.order(:first_name, :last_name, :email).to_a
          students = students.select { |student| invitation_status_for(student, school: current_school, role_name: "student") == params[:invitation_status] } if params[:invitation_status].present?

          limit, offset = pagination_params
          students.drop(offset).first(limit)
        end

        def set_student
          @student = current_school.users.joins(:roles).where(roles: { name: "student" }).distinct.find_by(id: params[:id])
          render_not_found unless @student
        end

        def student_create_params
          params.permit(:email, :first_name, :last_name, :locale, student_profile: %i[student_number grade_level guardian_name guardian_phone])
        end

        def student_update_params
          params.permit(:email, :first_name, :last_name, :locale, student_profile: %i[student_number grade_level guardian_name guardian_phone])
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
