module DiscussionSpaces
  class ResolveForScope
    Result = Struct.new(:success?, :space, :errors, :not_found, :forbidden, keyword_init: true)

    def initialize(user:, school:, params:)
      @user = user
      @school = school
      @params = params
    end

    def call
      return failure(["School context is required"]) unless school
      return failure(["Only assignment discussion spaces are auto-resolved right now"]) unless assignment_scope?

      assignment = Assignment.for_school(school.id).includes(:classroom, :subject, :teacher).find_by(id: params[:assignment_id])
      return Result.new(success?: false, space: nil, errors: [], not_found: true, forbidden: false) unless assignment

      space = existing_space_for(assignment) || build_space_for(assignment)
      policy = DiscussionSpacePolicy.new(user, space)
      return Result.new(success?: false, space: nil, errors: [], not_found: false, forbidden: true) unless policy.show?

      Result.new(success?: true, space: persist_if_needed(space), errors: [], not_found: false, forbidden: false)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :user, :school, :params

    def assignment_scope?
      params[:space_type].blank? || params[:space_type].to_s == "assignment"
    end

    def existing_space_for(assignment)
      DiscussionSpace.includes(:school, :assignment, :classroom, :subject).find_by(space_type: "assignment", assignment_id: assignment.id)
    end

    def build_space_for(assignment)
      DiscussionSpace.new(
        school: school,
        space_type: "assignment",
        title: "Дискусија за задачата",
        description: "Прашања и одговори поврзани со оваа задача.",
        status: "active",
        visibility: "students_and_teachers",
        assignment: assignment,
        created_by: assignment.teacher
      )
    end

    def persist_if_needed(space)
      return space if space.persisted?

      space.save!
      space
    rescue ActiveRecord::RecordNotUnique
      DiscussionSpace.includes(:school, :assignment, :classroom, :subject).find_by!(space_type: "assignment", assignment_id: space.assignment_id)
    end

    def failure(errors)
      Result.new(success?: false, space: nil, errors: Array(errors), not_found: false, forbidden: false)
    end
  end
end
