require "test_helper"

class Api::V1::LearningWorkflowEndpointsTest < ActionDispatch::IntegrationTest
  test "teacher can create assignment with steps" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)

    post "/api/v1/assignments", params: {
      classroom_id: classroom.id,
      subject_id: subject.id,
      title: "Нова задача",
      description: "Опис",
      teacher_notes: "Прочитај материјали пред да почнеш.",
      assignment_type: "homework",
      due_at: 2.days.from_now,
      max_points: 100,
      content_json: [
        { type: "heading", text: "Главна задача" },
        { type: "paragraph", text: "Следи ги упатствата по ред." }
      ],
      resources: [
        { title: "PDF упатство", resource_type: "pdf", file_url: "https://example.com/task.pdf", description: "Главен документ", is_required: true }
      ],
      steps: [{
        position: 1,
        title: "Чекор 1",
        content: "Реши",
        prompt: "Објасни како дојде до одговорот.",
        resource_url: "https://example.com/step-help",
        example_answer: "Прво ги издвојувам податоците...",
        evaluation_mode: "normalized_text",
        answer_keys: [
          { value: "x=5" }
        ],
        content_json: [{ type: "instruction", text: "Пиши целосни реченици." }]
      }]
    }, headers: auth_headers_for(teacher, school: school)

    assert_response :created
    payload = JSON.parse(response.body)
    assert_equal "Нова задача", payload["title"]
    assert_equal "Прочитај материјали пред да почнеш.", payload["teacher_notes"]
    assert_equal "normalized_text", payload["steps"].first["evaluation_mode"]
    assert_equal "x=5", payload["steps"].first["answer_keys"].first["value"]
  end

  test "student cannot create assignment" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)

    post "/api/v1/assignments", params: {
      classroom_id: classroom.id,
      subject_id: subject.id,
      title: "Нова задача"
    }, headers: auth_headers_for(student, school: school)

    assert_response :forbidden
  end

  test "teacher can update own assignment" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher, title: "Старо")

    patch "/api/v1/assignments/#{assignment.id}", params: { title: "Ново" }, headers: auth_headers_for(teacher, school: school)

    assert_response :success
    assert_equal "Ново", assignment.reload.title
  end

  test "other teacher cannot update assignment" do
    school = create_school
    teacher = create_teacher(school: school)
    other_teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher)

    patch "/api/v1/assignments/#{assignment.id}", params: { title: "Ново" }, headers: auth_headers_for(other_teacher, school: school)

    assert_response :forbidden
  end

  test "teacher can add assignment step" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher)

    post "/api/v1/assignments/#{assignment.id}/steps", params: { position: 1, title: "Чекор", content: "Содржина" }, headers: auth_headers_for(teacher, school: school)

    assert_response :created
    assert_equal 1, assignment.reload.assignment_steps.count
  end

  test "teacher can add assignment step with answer keys via json payload" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher)

    post "/api/v1/assignments/#{assignment.id}/steps",
         params: {
           position: 1,
           title: "Zbir",
           content: "25 + 25 = x",
           prompt: "Kolku e x?",
           resource_url: "",
           example_answer: "x = 10",
           step_type: "text",
           required: true,
           evaluation_mode: "regex",
           metadata: {},
           content_json: [{ type: "paragraph", text: "/" }],
           answer_keys: [
             {
               value: "x = 50",
               position: 1,
               tolerance: nil,
               case_sensitive: true,
               metadata: {}
             }
           ]
         },
         headers: auth_headers_for(teacher, school: school),
         as: :json

    assert_response :created
    payload = JSON.parse(response.body)
    assert_equal "regex", payload["evaluation_mode"]
    assert_equal 1, payload["answer_keys"].length
    assert_equal "x = 50", payload["answer_keys"].first["value"]
    assert_equal true, payload["answer_keys"].first["case_sensitive"]
  end

  test "teacher can update assignment step" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher)
    step = create_assignment_step(assignment: assignment, title: "Старо")

    patch "/api/v1/assignments/#{assignment.id}/steps/#{step.id}", params: { title: "Ново" }, headers: auth_headers_for(teacher, school: school)

    assert_response :success
    assert_equal "Ново", step.reload.title
  end

  test "teacher can publish assignment" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher, status: :draft, published_at: nil)

    post "/api/v1/assignments/#{assignment.id}/publish", headers: auth_headers_for(teacher, school: school)

    assert_response :success
    assert_equal "published", assignment.reload.status
    assert_equal 1, student.notifications.count
  end

  test "teacher assignment show includes resources and rich step fields" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    assignment = create_assignment(
      classroom: classroom,
      subject: subject,
      teacher: teacher,
      teacher_notes: "Забелешки за наставник",
      content_json: [{ type: "heading", text: "Наслов" }]
    )
    create_assignment_step(
      assignment: assignment,
      prompt: "Одговори со свои зборови.",
      resource_url: "https://example.com/step-resource",
      example_answer: "Пример одговор",
      evaluation_mode: "normalized_text",
      answer_keys: [{ value: "x=5" }]
    )
    create_assignment_resource(
      assignment: assignment,
      title: "Работен лист",
      resource_type: "file",
      file_url: "https://example.com/worksheet.docx"
    )

    get "/api/v1/assignments/#{assignment.id}", headers: auth_headers_for(teacher, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal "Забелешки за наставник", payload["teacher_notes"]
    assert_equal 1, payload["resources"].length
    assert_equal "Одговори со свои зборови.", payload["steps"].first["prompt"]
    assert_equal "Пример одговор", payload["steps"].first["example_answer"]
    assert_equal "normalized_text", payload["steps"].first["evaluation_mode"]
    assert_equal "x=5", payload["steps"].first["answer_keys"].first["value"]
  end

  test "teacher can update assignment step answer keys" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher)
    step = create_assignment_step(assignment: assignment)

    patch "/api/v1/assignments/#{assignment.id}/steps/#{step.id}", params: {
      evaluation_mode: "numeric",
      answer_keys: [{ value: "3.14", tolerance: "0.01" }]
    }, headers: auth_headers_for(teacher, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal "numeric", payload["evaluation_mode"]
    assert_equal "3.14", payload["answer_keys"].first["value"]
    assert_equal 0.01, payload["answer_keys"].first["tolerance"]
  end

  test "teacher can upload assignment resource file" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher)

    post "/api/v1/assignments/#{assignment.id}/resources", params: {
      title: "Упатство",
      resource_type: "file",
      description: "Локално прикачен документ",
      is_required: true,
      file: uploaded_test_file(filename: "assignment-guide.txt", content: "Материјал за задачата")
    }, headers: auth_headers_for(teacher, school: school)

    assert_response :created
    payload = JSON.parse(response.body)
    assert_equal "Упатство", payload["title"]
    assert_equal "assignment-guide.txt", payload.dig("uploaded_file", "filename")
    assert_includes payload["file_url"], "/rails/active_storage/blobs/"
    assert_equal 1, assignment.reload.assignment_resources.count
    assert assignment.assignment_resources.first.file.attached?
  end

  test "teacher can start submission for student" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher)

    post "/api/v1/assignments/#{assignment.id}/submissions", params: { student_id: student.id }, headers: auth_headers_for(teacher, school: school)

    assert_response :created
    assert_equal 1, Submission.count
  end

  test "teacher can update student submission feedback" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher)
    step = create_assignment_step(assignment: assignment)
    submission = create_submission(assignment: assignment, student: student, status: :in_progress, submitted_at: nil)

    patch "/api/v1/submissions/#{submission.id}", params: {
      feedback: "Провери уште еднаш",
      step_answers: [{ assignment_step_id: step.id, answer_text: "42" }]
    }, headers: auth_headers_for(teacher, school: school)

    assert_response :success
    assert_equal "Провери уште еднаш", submission.reload.feedback
  end

  test "teacher cannot submit student submission" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher)
    submission = create_submission(assignment: assignment, student: student, status: :in_progress, submitted_at: nil)

    post "/api/v1/submissions/#{submission.id}/submit", headers: auth_headers_for(teacher, school: school)

    assert_response :forbidden
  end

  test "comments index returns assignment comments for student" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher)
    Comment.create!(author: teacher, commentable: assignment, body: "Коментар")

    get "/api/v1/comments", params: { commentable_type: "Assignment", commentable_id: assignment.id }, headers: auth_headers_for(student, school: school)

    assert_response :success
    assert_equal 1, JSON.parse(response.body).length
  end

  test "student can create comment on submission" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher)
    submission = create_submission(assignment: assignment, student: student)

    post "/api/v1/comments", params: { commentable_type: "Submission", commentable_id: submission.id, body: "Мој коментар" }, headers: auth_headers_for(student, school: school)

    assert_response :created
    assert_equal 1, submission.reload.comments.count
  end

  test "notifications mark as read updates read_at" do
    school = create_school
    student = create_student(school: school)
    notification = Notification.create!(user: student, notification_type: "generic", title: "Наслов")

    post "/api/v1/notifications/#{notification.id}/mark_as_read", headers: auth_headers_for(student, school: school)

    assert_response :success
    assert_not_nil notification.reload.read_at
  end

  test "calendar create event attaches participants" do
    school = create_school
    teacher = create_teacher(school: school)
    student = create_student(school: school)

    post "/api/v1/calendar/events", params: {
      title: "Настан",
      starts_at: 1.day.from_now,
      participant_ids: [student.id]
    }, headers: auth_headers_for(teacher, school: school)

    assert_response :created
    payload = JSON.parse(response.body)
    assert_equal 1, payload["participants"].length
  end

  test "calendar update event changes title" do
    school = create_school
    teacher = create_teacher(school: school)
    event = CalendarEvent.create!(school: school, title: "Стар настан", starts_at: 1.day.from_now)

    patch "/api/v1/calendar/events/#{event.id}", params: { title: "Нов настан" }, headers: auth_headers_for(teacher, school: school)

    assert_response :success
    assert_equal "Нов настан", event.reload.title
  end
end
