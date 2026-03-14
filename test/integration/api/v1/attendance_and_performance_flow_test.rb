require "test_helper"

class Api::V1::AttendanceAndPerformanceFlowTest < ActionDispatch::IntegrationTest
  test "teacher can assign homeroom mark attendance and load classroom performance overview" do
    teacher_role = Role.create!(name: "teacher")
    student_role = Role.create!(name: "student")

    school = School.create!(name: "ОУ Кирил Пејчиновиќ", code: "OU-KP")
    teacher = User.create!(email: "attendance.teacher@example.com", password: "password123", password_confirmation: "password123", first_name: "Ана")
    student = User.create!(email: "attendance.student@example.com", password: "password123", password_confirmation: "password123", first_name: "Иван")

    UserRole.create!(user: teacher, role: teacher_role)
    UserRole.create!(user: student, role: student_role)
    SchoolUser.create!(school: school, user: teacher)
    SchoolUser.create!(school: school, user: student)

    classroom = Classroom.create!(school: school, name: "8-B", grade_level: "8")
    TeacherClassroom.create!(classroom: classroom, user: teacher)
    ClassroomUser.create!(classroom: classroom, user: student)
    subject = Subject.create!(school: school, name: "Биологија")
    TeacherSubject.create!(teacher: teacher, subject: subject)

    assignment = Assignment.create!(
      classroom: classroom,
      subject: subject,
      teacher: teacher,
      title: "Лекција за клетка",
      status: :published,
      due_at: 1.day.ago
    )
    submission = Submission.create!(
      assignment: assignment,
      student: student,
      status: :reviewed,
      submitted_at: 2.days.ago,
      reviewed_at: 1.day.ago,
      total_score: 95
    )
    Grade.create!(submission: submission, teacher: teacher, score: 95, max_score: 100, feedback: "Одлично", graded_at: Time.current)

    headers = auth_headers_for(teacher, school: school)

    post "/api/v1/classrooms/#{classroom.id}/homeroom_assignment", params: { teacher_id: teacher.id, starts_on: Date.current }, headers: headers
    assert_response :created

    post "/api/v1/attendance_records", params: {
      classroom_id: classroom.id,
      subject_id: subject.id,
      attendance_date: Date.current,
      records: [
        { student_id: student.id, status: "present", note: "На време" }
      ]
    }, headers: headers
    assert_response :created

    get "/api/v1/teacher/homerooms", headers: headers
    assert_response :success
    homerooms = JSON.parse(response.body)
    assert_equal 1, homerooms.length

    get "/api/v1/classrooms/#{classroom.id}/performance_overview", headers: headers
    assert_response :success
    overview = JSON.parse(response.body)
    assert_equal classroom.id, overview["classroom_id"]
    assert_equal 1, overview["student_count"]
    assert_equal 95.0, overview["average_grade"].to_f
  end
end
