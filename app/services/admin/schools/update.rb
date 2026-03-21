module Admin
  module Schools
    class Update
      Result = Struct.new(:success?, :school, :errors, keyword_init: true)

      def initialize(school:, params:)
        @school = school
        @params = params
      end

      def call
        school.update!(params)
        Result.new(success?: true, school: school, errors: [])
      rescue ActiveRecord::RecordInvalid => e
        Result.new(success?: false, school: school, errors: e.record.errors.full_messages)
      end

      private

      attr_reader :school, :params
    end
  end
end
