module Api
  module V1
    module Teacher
      class DashboardsController < BaseController
        def show
          require_role!("teacher", "admin")
          return if performed?

          payload = Dashboards::BuildTeacherDashboard.new(
            teacher: current_user,
            school: current_school
          ).call

          render json: payload
        end
      end
    end
  end
end
