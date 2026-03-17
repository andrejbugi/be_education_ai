require "test_helper"

class Api::V1::AnnouncementsFlowTest < ActionDispatch::IntegrationTest
  test "teacher can create and publish announcement and student can read it" do
    teacher_role = Role.create!(name: "teacher")
    student_role = Role.create!(name: "student")

    school = School.create!(name: "ОУ Гоце Делчев", code: "OU-GD")
    teacher = User.create!(email: "announce.teacher@example.com", password: "password123", password_confirmation: "password123")
    student = User.create!(email: "announce.student@example.com", password: "password123", password_confirmation: "password123")

    UserRole.create!(user: teacher, role: teacher_role)
    UserRole.create!(user: student, role: student_role)
    SchoolUser.create!(school: school, user: teacher)
    SchoolUser.create!(school: school, user: student)

    classroom = Classroom.create!(school: school, name: "7-A", grade_level: "7")
    TeacherClassroom.create!(classroom: classroom, user: teacher)
    ClassroomUser.create!(classroom: classroom, user: student)

    teacher_headers = auth_headers_for(teacher, school: school)
    student_headers = auth_headers_for(student, school: school)

    post "/api/v1/announcements", params: {
      classroom_id: classroom.id,
      title: "Важно известување",
      body: "Утре донесете тетратки.",
      audience_type: "classroom",
      priority: "important"
    }, headers: teacher_headers

    assert_response :created
    announcement_id = JSON.parse(response.body)["id"]

    post "/api/v1/announcements/#{announcement_id}/publish", headers: teacher_headers
    assert_response :success

    get "/api/v1/announcements", headers: student_headers
    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal 1, payload.length
    assert_equal "Важно известување", payload.first["title"]

    get "/api/v1/notifications", headers: student_headers
    assert_response :success
    notifications = JSON.parse(response.body)
    assert_equal 1, notifications["unread_count"]
  end

  test "teacher cannot create classroom announcement without classroom_id" do
    school = create_school(code: "ANN-CLASS")
    teacher = create_teacher(school: school, email: "announce.teacher.two@example.com")

    post "/api/v1/announcements", params: {
      title: "Важно известување",
      body: "Ова нема таргет клас.",
      audience_type: "classroom",
      priority: "important"
    }, headers: auth_headers_for(teacher, school: school)

    assert_response :unprocessable_entity
    payload = JSON.parse(response.body)
    assert_includes payload["errors"], "Classroom must be present for classroom audience"
  end

  test "creating a published classroom announcement notifies matching students immediately" do
    school = create_school(code: "ANN-PUBLISHED")
    teacher = create_teacher(school: school, email: "announce.teacher.published@example.com")
    classroom = create_classroom(school: school, teacher: teacher, name: "9-A")
    student = create_student(school: school, classroom: classroom, email: "announce.student.published@example.com")

    post "/api/v1/announcements", params: {
      classroom_id: classroom.id,
      title: "Тест објава",
      body: "Ова е директно објавена класна објава.",
      audience_type: "classroom",
      status: "published"
    }, headers: auth_headers_for(teacher, school: school)

    assert_response :created

    notifications = student.notifications.order(:created_at)
    assert_equal 1, notifications.count
    assert_equal "announcement_published", notifications.last.notification_type
    assert_equal "Тест објава", notifications.last.title
  end

  test "teacher can upload a file to an announcement and student can read it" do
    school = create_school(code: "ANN-FILE")
    teacher = create_teacher(school: school, email: "announce.teacher.file@example.com")
    student = create_student(school: school, email: "announce.student.file@example.com")

    teacher_headers = auth_headers_for(teacher, school: school)
    student_headers = auth_headers_for(student, school: school)

    post "/api/v1/announcements", params: {
      title: "Училишен распоред",
      body: "Погледнете го прикачениот документ.",
      audience_type: "school",
      status: "published",
      file: uploaded_test_file(filename: "school-notice.pdf", content_type: "application/pdf", content: "School notice")
    }, headers: teacher_headers

    assert_response :created
    payload = JSON.parse(response.body)
    assert_equal "school-notice.pdf", payload.dig("uploaded_file", "filename")
    assert_includes payload["file_url"], "/rails/active_storage/blobs/"

    get "/api/v1/announcements/#{payload["id"]}", headers: student_headers

    assert_response :success
    detail_payload = JSON.parse(response.body)
    assert_equal "school-notice.pdf", detail_payload.dig("uploaded_file", "filename")
    assert_includes detail_payload["file_url"], "/rails/active_storage/blobs/"
  end

  test "teacher can remove an uploaded announcement file" do
    school = create_school(code: "ANN-REMOVE")
    teacher = create_teacher(school: school, email: "announce.teacher.remove@example.com")
    announcement = Announcement.create!(
      school: school,
      author: teacher,
      title: "Прилог",
      body: "Има прилог",
      audience_type: "school",
      status: :published,
      published_at: Time.current
    )
    announcement.file.attach(
      uploaded_test_file(filename: "old-note.txt", content_type: "text/plain", content: "Old note")
    )

    patch "/api/v1/announcements/#{announcement.id}", params: {
      remove_file: true
    }, headers: auth_headers_for(teacher, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_nil payload["file_url"]
    assert_nil payload["uploaded_file"]
    assert_not announcement.reload.file.attached?
  end
end
