require "test_helper"

class Api::V1::DiscussionsFlowTest < ActionDispatch::IntegrationTest
  test "assignment discussion space resolves and supports thread and reply flow" do
    school = create_school(code: "DISCUSS-ASSIGN")
    teacher = create_teacher(school: school, email: "discussion.teacher@example.com")
    classroom = create_classroom(school: school, teacher: teacher, name: "7-A")
    subject = create_subject(school: school, teacher: teacher, name: "Математика")
    student = create_student(school: school, classroom: classroom, email: "discussion.student@example.com")
    outsider_classroom = create_classroom(school: school, name: "7-B")
    outsider_student = create_student(school: school, classroom: outsider_classroom, email: "discussion.outsider@example.com")
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher, title: "Равенки", status: :published)

    student_headers = auth_headers_for(student, school: school)
    teacher_headers = auth_headers_for(teacher, school: school)
    outsider_headers = auth_headers_for(outsider_student, school: school)

    get "/api/v1/discussion_spaces", params: {
      space_type: "assignment",
      assignment_id: assignment.id
    }, headers: student_headers

    assert_response :success
    spaces_payload = JSON.parse(response.body)
    assert_equal 1, spaces_payload.length
    space_payload = spaces_payload.first
    space_id = space_payload["id"]
    assert_equal "assignment", space_payload["space_type"]
    assert_equal assignment.id, space_payload.dig("assignment", "id")
    assert_equal classroom.id, space_payload.dig("classroom", "id")
    assert_equal subject.id, space_payload.dig("subject", "id")
    assert_equal true, space_payload.dig("permissions", "can_create_thread")

    get "/api/v1/discussion_spaces", params: {
      space_type: "assignment",
      assignment_id: assignment.id
    }, headers: outsider_headers

    assert_response :forbidden

    post "/api/v1/discussion_spaces/#{space_id}/threads", params: {
      title: "Прашања за домашната",
      files: [
        uploaded_test_file(filename: "task-notes.pdf", content_type: "application/pdf", content: "Task notes"),
        uploaded_test_file(filename: "draft-plan.txt", content_type: "text/plain", content: "Draft plan")
      ]
    }, headers: student_headers

    assert_response :created
    thread_payload = JSON.parse(response.body)
    thread_id = thread_payload["id"]
    assert_equal "Прашања за домашната", thread_payload["title"]
    assert_equal student.id, thread_payload.dig("creator", "id")
    assert_equal "student", thread_payload.dig("creator", "role")
    assert_equal true, thread_payload.dig("permissions", "can_reply")
    assert_equal 2, thread_payload["attachments"].length
    assert_equal "task-notes.pdf", thread_payload.dig("attachments", 0, "file_name")
    assert_equal "pdf", thread_payload.dig("attachments", 0, "attachment_type")

    get "/api/v1/discussion_spaces/#{space_id}/threads", headers: teacher_headers
    assert_response :success
    threads_payload = JSON.parse(response.body)
    assert_equal 1, threads_payload.length
    assert_equal true, threads_payload.first.dig("permissions", "can_moderate")
    assert_equal 2, threads_payload.first["attachments"].length

    post "/api/v1/discussion_threads/#{thread_id}/posts", params: {
      files: [
        uploaded_test_file(filename: "solution-example.pdf", content_type: "application/pdf", content: "Solution example")
      ]
    }, headers: teacher_headers

    assert_response :created
    teacher_post_payload = JSON.parse(response.body)
    assert_equal teacher.id, teacher_post_payload.dig("author", "id")
    assert_equal "teacher", teacher_post_payload.dig("author", "role")
    assert_equal 1, teacher_post_payload["attachments"].length
    assert_equal "solution-example.pdf", teacher_post_payload.dig("attachments", 0, "file_name")

    post "/api/v1/discussion_threads/#{thread_id}/posts", params: {
      body: "Фала многу.",
      parent_post_id: teacher_post_payload["id"]
    }, headers: student_headers

    assert_response :created
    reply_payload = JSON.parse(response.body)
    assert_equal teacher_post_payload["id"], reply_payload["parent_post_id"]

    get "/api/v1/discussion_threads/#{thread_id}", headers: student_headers
    assert_response :success
    thread_detail_payload = JSON.parse(response.body)
    assert_equal space_id, thread_detail_payload.dig("discussion_space", "id")
    assert_equal 2, thread_detail_payload["attachments"].length

    get "/api/v1/discussion_threads/#{thread_id}/posts", headers: student_headers
    assert_response :success
    posts_payload = JSON.parse(response.body)
    assert_equal 2, posts_payload.length
    assert_equal 1, posts_payload.first["attachments"].length
    assert_equal 1, posts_payload.first["replies_count"]
  end

  test "teacher moderation works and locked or hidden content is enforced for students" do
    school = create_school(code: "DISCUSS-MOD")
    teacher = create_teacher(school: school, email: "discussion.mod.teacher@example.com")
    classroom = create_classroom(school: school, teacher: teacher, name: "8-A")
    subject = create_subject(school: school, teacher: teacher, name: "Физика")
    student = create_student(school: school, classroom: classroom, email: "discussion.mod.student@example.com")
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher, title: "Движење", status: :published)

    teacher_headers = auth_headers_for(teacher, school: school)
    student_headers = auth_headers_for(student, school: school)

    get "/api/v1/discussion_spaces", params: {
      space_type: "assignment",
      assignment_id: assignment.id
    }, headers: teacher_headers
    assert_response :success
    space_id = JSON.parse(response.body).first["id"]

    post "/api/v1/discussion_spaces/#{space_id}/threads", params: {
      title: "Прашања за тестот",
      body: "Овде прашувајте за подготовката."
    }, headers: student_headers
    assert_response :created
    thread_id = JSON.parse(response.body)["id"]

    post "/api/v1/discussion_threads/#{thread_id}/posts", params: {
      body: "Кога е рокот?"
    }, headers: student_headers
    assert_response :created
    post_id = JSON.parse(response.body)["id"]

    post "/api/v1/discussion_threads/#{thread_id}/lock", headers: student_headers
    assert_response :forbidden

    post "/api/v1/discussion_threads/#{thread_id}/lock", headers: teacher_headers
    assert_response :success
    locked_thread_payload = JSON.parse(response.body)
    assert_equal true, locked_thread_payload["locked"]

    post "/api/v1/discussion_threads/#{thread_id}/posts", params: {
      body: "Нова порака во заклучена тема."
    }, headers: student_headers
    assert_response :unprocessable_entity

    post "/api/v1/discussion_posts/#{post_id}/hide", headers: teacher_headers
    assert_response :success
    hidden_post_payload = JSON.parse(response.body)
    assert_equal "hidden", hidden_post_payload["status"]

    get "/api/v1/discussion_threads/#{thread_id}/posts", headers: student_headers
    assert_response :success
    assert_equal [], JSON.parse(response.body)

    get "/api/v1/discussion_threads/#{thread_id}/posts", headers: teacher_headers
    assert_response :success
    teacher_posts_payload = JSON.parse(response.body)
    assert_equal 1, teacher_posts_payload.length
    assert_equal "hidden", teacher_posts_payload.first["status"]

    post "/api/v1/discussion_posts/#{post_id}/unhide", headers: teacher_headers
    assert_response :success
    assert_equal "visible", JSON.parse(response.body)["status"]

    post "/api/v1/discussion_threads/#{thread_id}/pin", headers: teacher_headers
    assert_response :success
    assert_equal true, JSON.parse(response.body)["pinned"]

    post "/api/v1/discussion_threads/#{thread_id}/archive", headers: teacher_headers
    assert_response :success
    assert_equal "archived", JSON.parse(response.body)["status"]

    get "/api/v1/discussion_threads/#{thread_id}", headers: student_headers
    assert_response :forbidden
  end
end
