require "test_helper"

class Submissions::EvaluateStepAnswerTest < ActiveSupport::TestCase
  test "normalized text mode ignores operator spacing" do
    school = School.create!(name: "ОУ Св. Климент", code: "OU-SK")
    teacher = User.create!(email: "teacher-eval@example.com", password: "password123", password_confirmation: "password123")
    classroom = Classroom.create!(school: school, name: "7-A")
    subject = Subject.create!(school: school, name: "Математика")
    assignment = Assignment.create!(classroom: classroom, subject: subject, teacher: teacher, title: "Тест", status: :published)
    step = AssignmentStep.create!(assignment: assignment, position: 1, title: "Реши", evaluation_mode: "normalized_text")
    AssignmentStepAnswerKey.create!(assignment_step: step, value: "x=5", position: 1)

    result = Submissions::EvaluateStepAnswer.new(assignment_step: step, answer_text: "x = 5").call

    assert_equal :correct, result.status
  end

  test "numeric mode supports tolerance" do
    school = School.create!(name: "ОУ Гоце Делчев", code: "OU-GD")
    teacher = User.create!(email: "teacher-numeric@example.com", password: "password123", password_confirmation: "password123")
    classroom = Classroom.create!(school: school, name: "8-A")
    subject = Subject.create!(school: school, name: "Физика")
    assignment = Assignment.create!(classroom: classroom, subject: subject, teacher: teacher, title: "Тест 2", status: :published)
    step = AssignmentStep.create!(assignment: assignment, position: 1, title: "Број", evaluation_mode: "numeric")
    AssignmentStepAnswerKey.create!(assignment_step: step, value: "3.14", tolerance: 0.01, position: 1)

    result = Submissions::EvaluateStepAnswer.new(assignment_step: step, answer_text: "3.145").call

    assert_equal :correct, result.status
  end
end
