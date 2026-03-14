module HomeroomAssignments
  class AssignTeacher
    Result = Struct.new(:success?, :assignment, :errors, keyword_init: true)

    def initialize(classroom:, teacher:, school:, starts_on: Date.current, actor: nil)
      @classroom = classroom
      @teacher = teacher
      @school = school
      @starts_on = starts_on
      @actor = actor
    end

    def call
      assignment = nil

      HomeroomAssignment.transaction do
        deactivate_existing_assignments!
        sync_teacher_classrooms!

        assignment = HomeroomAssignment.create!(
          school: school,
          classroom: classroom,
          teacher: teacher,
          active: true,
          starts_on: starts_on
        )
      end

      Result.new(success?: true, assignment: assignment, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, assignment: e.record, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :classroom, :teacher, :school, :starts_on, :actor

    def deactivate_existing_assignments!
      classroom.homeroom_assignments.active.find_each do |existing|
        existing.update!(active: false, ends_on: starts_on - 1.day)
      end

      classroom.teacher_classrooms.update_all(homeroom: false)
    end

    def sync_teacher_classrooms!
      teacher_classroom = TeacherClassroom.find_or_initialize_by(classroom: classroom, user: teacher)
      teacher_classroom.homeroom = true
      teacher_classroom.save!
    end
  end
end
