module Announcements
  class Create
    Result = Struct.new(:success?, :announcement, :errors, keyword_init: true)

    def initialize(author:, school:, params:)
      @author = author
      @school = school
      @params = params
    end

    def call
      announcement = school.announcements.new(params.merge(author: author))
      announcement.status ||= :draft

      if announcement.save
        Result.new(success?: true, announcement: announcement, errors: [])
      else
        Result.new(success?: false, announcement: announcement, errors: announcement.errors.full_messages)
      end
    end

    private

    attr_reader :author, :school, :params
  end
end
