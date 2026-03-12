module Api
  module V1
    module Student
      class DashboardsController < BaseController
        def show
          require_role!("student")
          return if performed?

          payload = Dashboards::BuildStudentDashboard.new(
            student: current_user,
            school: current_school
          ).call

          render json: payload
        end
      end
    end
  end
end
