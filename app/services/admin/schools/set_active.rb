module Admin
  module Schools
    class SetActive
      Result = Struct.new(:success?, :school, :errors, keyword_init: true)

      def initialize(school:, active:)
        @school = school
        @active = active
      end

      def call
        school.update!(active: active)
        Result.new(success?: true, school: school, errors: [])
      rescue ActiveRecord::RecordInvalid => e
        Result.new(success?: false, school: school, errors: e.record.errors.full_messages)
      end

      private

      attr_reader :school, :active
    end
  end
end
