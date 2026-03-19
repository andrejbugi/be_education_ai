require "test_helper"

class Gamification::RefreshStudentProgressTest < ActiveSupport::TestCase
  include ApiTestFactory

  test "refresh builds persistent profile and awards milestone badges" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)

    3.times do |index|
      assignment = create_assignment(
        classroom: classroom,
        subject: subject,
        teacher: teacher,
        due_at: (index + 1).days.ago
      )
      submission = create_submission(
        assignment: assignment,
        student: student,
        status: :reviewed,
        started_at: (4 - index).days.ago,
        submitted_at: (2 - index).days.ago,
        reviewed_at: (2 - index).days.ago,
        total_score: 96
      )
      create_grade(submission: submission, teacher: teacher, score: 96, max_score: 100)
    end

    5.times do |index|
      AttendanceRecord.create!(
        school: school,
        classroom: classroom,
        subject: subject,
        student: student,
        teacher: teacher,
        attendance_date: index.days.ago.to_date,
        status: :present
      )
    end

    AiSession.create!(
      school: school,
      user: student,
      subject: subject,
      title: "Practice",
      session_type: :practice,
      status: :completed,
      started_at: 1.day.ago,
      last_activity_at: Time.current,
      ended_at: Time.current,
      context_data: {}
    )

    result = Gamification::RefreshStudentProgress.new(student: student, school: school).call

    assert result.success?
    assert_equal 3, result.profile.completed_assignments_count
    assert_equal 3, result.profile.graded_assignments_count
    assert_operator result.profile.total_xp, :>=, 145
    assert_operator result.profile.current_level, :>=, 2
    assert_equal 5, result.profile.current_streak
    assert_equal 5, result.profile.longest_streak
    assert_equal 5, result.profile.badges_count
    assert_equal %w[ai_explorer attendance_star first_completion high_achiever streak_3], result.profile.student_badges.order(:code).pluck(:code)
  end

  test "refresh includes daily quiz rewards in xp totals and activity streaks" do
    school = create_school
    student = create_student(school: school)

    StudentRewardEvent.create!(
      school: school,
      student: student,
      source_type: StudentRewardEvent::SOURCE_DAILY_QUIZ,
      source_id: 42,
      awarded_on: Date.current,
      xp_amount: 1,
      metadata: {}
    )

    result = Gamification::RefreshStudentProgress.new(student: student, school: school).call

    assert result.success?
    assert_equal 1, result.profile.total_xp
    assert_equal Date.current, result.profile.last_active_on
    assert_equal 1, result.profile.current_streak
    assert_equal 1, result.profile.metadata.dig("xp_breakdown", "daily_quiz")
    assert_equal 1, result.profile.metadata.dig("rewards", "daily_quiz_events")
  end
end
