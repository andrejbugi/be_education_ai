module Api
  module V1
    module Admin
      class BaseController < Api::V1::BaseController
        include AdminSerialization

        before_action :require_admin!

        private

        def require_admin!
          require_role!("admin")
        end

        def require_current_school!
          return if current_school.present?

          render_forbidden
        end

        def admin_schools_scope
          current_user.schools
        end
      end
    end
  end
end
