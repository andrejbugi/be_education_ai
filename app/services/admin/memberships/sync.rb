module Admin
  module Memberships
    class Sync
      Result = Struct.new(:success?, :errors, keyword_init: true)

      def initialize(user:, school:, association:, ids:)
        @user = user
        @school = school
        @association = association
        @ids = Array(ids).map(&:to_i).uniq
      end

      def call
        target_relation = scoped_target_relation
        return Result.new(success?: false, errors: ["Unsupported membership sync"]) unless target_relation

        missing_ids = ids - target_relation.pluck(:id)
        return Result.new(success?: false, errors: ["Some selected records do not belong to the selected school"]) if missing_ids.any?

        ActiveRecord::Base.transaction do
          current_ids = current_ids_for_association
          ids_to_remove = current_ids - ids
          ids_to_add = ids - current_ids

          remove_ids(ids_to_remove)
          add_ids(ids_to_add)
        end

        Result.new(success?: true, errors: [])
      end

      private

      attr_reader :user, :school, :association, :ids

      def scoped_target_relation
        case association
        when :teacher_subjects
          school.subjects
        when :teacher_classrooms, :student_classrooms
          school.classrooms
        end
      end

      def current_ids_for_association
        case association
        when :teacher_subjects
          user.subjects.where(school_id: school.id).pluck(:id)
        when :teacher_classrooms
          user.teaching_classrooms.where(school_id: school.id).pluck(:id)
        when :student_classrooms
          user.student_classrooms.where(school_id: school.id).pluck(:id)
        else
          []
        end
      end

      def remove_ids(ids_to_remove)
        return if ids_to_remove.empty?

        case association
        when :teacher_subjects
          user.teacher_subjects.where(subject_id: ids_to_remove).delete_all
        when :teacher_classrooms
          user.teacher_classrooms.where(classroom_id: ids_to_remove).delete_all
        when :student_classrooms
          user.classroom_users.where(classroom_id: ids_to_remove).delete_all
        end
      end

      def add_ids(ids_to_add)
        ids_to_add.each do |id|
          case association
          when :teacher_subjects
            user.teacher_subjects.create!(subject_id: id)
          when :teacher_classrooms
            user.teacher_classrooms.create!(classroom_id: id)
          when :student_classrooms
            user.classroom_users.create!(classroom_id: id)
          end
        end
      end
    end
  end
end
