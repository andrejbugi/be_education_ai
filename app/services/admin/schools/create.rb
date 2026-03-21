module Admin
  module Schools
    class Create
      Result = Struct.new(:success?, :school, :errors, keyword_init: true)

      def initialize(admin:, params:)
        @admin = admin
        @params = params
      end

      def call
        school = nil

        School.transaction do
          school = School.create!(params)
          SchoolUser.create!(school: school, user: admin)
        end

        Result.new(success?: true, school: school, errors: [])
      rescue ActiveRecord::RecordInvalid => e
        Result.new(success?: false, school: e.record.is_a?(School) ? e.record : school, errors: e.record.errors.full_messages)
      end

      private

      attr_reader :admin, :params
    end
  end
end
