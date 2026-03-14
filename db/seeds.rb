Role::BASE_ROLES.each do |role_name|
  Role.find_or_create_by!(name: role_name)
end

def find_role!(name)
  Role.find_by!(name: name)
end

def academic_year_for(date = Date.current)
  start_year = date.month >= 9 ? date.year : date.year - 1
  "#{start_year}/#{start_year + 1}"
end

def upsert_user(email:, first_name:, last_name:, password:, roles:, school:)
  user = User.find_or_initialize_by(email: email.downcase)
  user.first_name = first_name
  user.last_name = last_name
  user.active = true
  user.locale = "mk"
  user.password = password
  user.password_confirmation = password
  user.save!

  roles.each do |role_name|
    UserRole.find_or_create_by!(user: user, role: find_role!(role_name))
  end

  SchoolUser.find_or_create_by!(school: school, user: user)
  user
end

def upsert_teacher_profile(user:, school:, title:, bio: nil)
  profile = user.teacher_profile || user.build_teacher_profile
  profile.school = school
  profile.title = title
  profile.bio = bio || "Наставник во #{school.name}"
  profile.save!
  profile
end

def upsert_student_profile(user:, school:, grade_level:, student_number:, guardian_name:, guardian_phone:)
  profile = user.student_profile || user.build_student_profile
  profile.school = school
  profile.grade_level = grade_level
  profile.student_number = student_number
  profile.guardian_name = guardian_name
  profile.guardian_phone = guardian_phone
  profile.save!
  profile
end

def upsert_classroom(school:, name:, grade_level:, academic_year:)
  classroom = Classroom.find_or_initialize_by(school: school, name: name, academic_year: academic_year)
  classroom.grade_level = grade_level
  classroom.save!
  classroom
end

def assign_student_to_classroom(student:, classroom:, joined_at:)
  record = ClassroomUser.find_or_initialize_by(classroom: classroom, user: student)
  record.joined_at = joined_at
  record.save!
end

def assign_teacher_to_classroom(teacher:, classroom:, homeroom: false)
  assignment = TeacherClassroom.find_or_initialize_by(classroom: classroom, user: teacher)
  assignment.homeroom = homeroom
  assignment.save!
  assignment
end

def upsert_subject(school:, name:, code:)
  subject = Subject.find_or_initialize_by(school: school, name: name)
  subject.code = code
  subject.save!
  subject
end

def assign_teacher_to_subject(teacher:, subject:)
  TeacherSubject.find_or_create_by!(teacher: teacher, subject: subject)
end

def upsert_assignment(classroom:, subject:, teacher:, title:, description:, teacher_notes:, content_json:, assignment_type:, status:, due_at:, published_at:, max_points:, settings:)
  assignment = Assignment.find_or_initialize_by(classroom: classroom, title: title)
  assignment.subject = subject
  assignment.teacher = teacher
  assignment.description = description
  assignment.teacher_notes = teacher_notes
  assignment.content_json = content_json
  assignment.assignment_type = assignment_type
  assignment.status = status
  assignment.due_at = due_at
  assignment.published_at = published_at
  assignment.max_points = max_points
  assignment.settings = settings
  assignment.save!
  assignment
end

def upsert_assignment_step(assignment:, position:, title:, content:, prompt:, resource_url:, example_answer:, content_json:, step_type:, required:, metadata:)
  step = AssignmentStep.find_or_initialize_by(assignment: assignment, position: position)
  step.title = title
  step.content = content
  step.prompt = prompt
  step.resource_url = resource_url
  step.example_answer = example_answer
  step.content_json = content_json
  step.step_type = step_type
  step.required = required
  step.metadata = metadata
  step.save!
  step
end

def upsert_assignment_resource(assignment:, title:, resource_type:, file_url: nil, external_url: nil, embed_url: nil, description:, position:, is_required:, metadata: {})
  resource = AssignmentResource.find_or_initialize_by(assignment: assignment, position: position)
  resource.title = title
  resource.resource_type = resource_type
  resource.file_url = file_url
  resource.external_url = external_url
  resource.embed_url = embed_url
  resource.description = description
  resource.is_required = is_required
  resource.metadata = metadata
  resource.save!
  resource
end

def upsert_submission(assignment:, student:, status:, started_at:, submitted_at:, reviewed_at:, late:, total_score:, feedback:)
  submission = Submission.find_or_initialize_by(assignment: assignment, student: student)
  submission.status = status
  submission.started_at = started_at
  submission.submitted_at = submitted_at
  submission.reviewed_at = reviewed_at
  submission.late = late
  submission.total_score = total_score
  submission.feedback = feedback
  submission.save!
  submission
end

def upsert_step_answer(submission:, assignment_step:, answer_text:, answer_data:, status:, answered_at:)
  step_answer = SubmissionStepAnswer.find_or_initialize_by(
    submission: submission,
    assignment_step: assignment_step
  )
  step_answer.answer_text = answer_text
  step_answer.answer_data = answer_data
  step_answer.status = status
  step_answer.answered_at = answered_at
  step_answer.save!
  step_answer
end

def upsert_grade(submission:, teacher:, score:, max_score:, feedback:, graded_at:)
  grade = Grade.find_or_initialize_by(submission: submission, teacher: teacher)
  grade.score = score
  grade.max_score = max_score
  grade.feedback = feedback
  grade.graded_at = graded_at
  grade.save!
  grade
end

def upsert_comment(author:, commentable:, body:, visibility: "all")
  comment = Comment.find_or_initialize_by(author: author, commentable: commentable, body: body)
  comment.visibility = visibility
  comment.save!
  comment
end

def upsert_calendar_event(school:, title:, description:, event_type:, starts_at:, ends_at:, all_day:, assignment: nil, metadata: {})
  event = CalendarEvent.find_or_initialize_by(school: school, title: title, starts_at: starts_at)
  event.assignment = assignment
  event.description = description
  event.event_type = event_type
  event.ends_at = ends_at
  event.all_day = all_day
  event.metadata = metadata
  event.save!
  event
end

def upsert_event_participant(calendar_event:, user:, role:, attendance_status:)
  participant = EventParticipant.find_or_initialize_by(calendar_event: calendar_event, user: user)
  participant.role = role
  participant.attendance_status = attendance_status
  participant.save!
  participant
end

def upsert_notification(user:, actor:, notification_type:, title:, body:, payload:, read_at: nil)
  notification = Notification.find_or_initialize_by(
    user: user,
    notification_type: notification_type,
    title: title,
    body: body
  )
  notification.actor = actor
  notification.payload = payload
  notification.read_at = read_at
  notification.save!
  notification
end

def upsert_activity_log(user:, action:, trackable:, occurred_at:, metadata: {})
  log = ActivityLog.find_or_initialize_by(
    user: user,
    action: action,
    trackable: trackable,
    occurred_at: occurred_at
  )
  log.metadata = metadata
  log.save!
  log
end

def upsert_homeroom_assignment(school:, classroom:, teacher:, starts_on:, active: true, ends_on: nil)
  assignment = HomeroomAssignment.find_or_initialize_by(
    school: school,
    classroom: classroom,
    teacher: teacher,
    starts_on: starts_on
  )
  assignment.active = active
  assignment.ends_on = ends_on
  assignment.save!
  assignment
end

def upsert_announcement(school:, author:, title:, body:, audience_type:, classroom: nil, subject: nil, status:, priority:, published_at:, starts_at: nil, ends_at: nil)
  announcement = Announcement.find_or_initialize_by(school: school, author: author, title: title)
  announcement.body = body
  announcement.classroom = classroom
  announcement.subject = subject
  announcement.audience_type = audience_type
  announcement.status = status
  announcement.priority = priority
  announcement.published_at = published_at
  announcement.starts_at = starts_at
  announcement.ends_at = ends_at
  announcement.save!
  announcement
end

def upsert_attendance_record(school:, classroom:, student:, teacher:, attendance_date:, status:, subject: nil, note: nil)
  record = AttendanceRecord.find_or_initialize_by(
    school: school,
    classroom: classroom,
    subject: subject,
    student: student,
    attendance_date: attendance_date
  )
  record.teacher = teacher
  record.status = status
  record.note = note
  record.save!
  record
end

def upsert_ai_session(school:, user:, title:, session_type:, status:, started_at:, last_activity_at:, assignment: nil, submission: nil, subject: nil, context_data: {}, ended_at: nil)
  session = AiSession.find_or_initialize_by(school: school, user: user, title: title)
  session.assignment = assignment
  session.submission = submission
  session.subject = subject
  session.session_type = session_type
  session.status = status
  session.started_at = started_at
  session.last_activity_at = last_activity_at
  session.ended_at = ended_at
  session.context_data = context_data
  session.save!
  session
end

def upsert_ai_message(ai_session:, sequence_number:, role:, message_type:, content:, metadata: {})
  message = AiMessage.find_or_initialize_by(ai_session: ai_session, sequence_number: sequence_number)
  message.role = role
  message.message_type = message_type
  message.content = content
  message.metadata = metadata
  message.save!
  message
end

FIRST_NAMES = %w[
  Ана Петар Елена Марија Иван Сара Давид Ема Никола Теа
  Јована Андреј Мила Коста Лина Филип Тамара Лука Ива Борис
].freeze

LAST_NAMES = %w[
  Трајковска Миленков Јовановска Стојанова Николов Попова Тодоров Андоновска
  Георгиев Илиевска Наумов Петровска Димитрова Костовска Ристов Марковска
  Велков Христовска Стефанов Митевска
].freeze

SCHOOL_BLUEPRINTS = [
  {
    code: "OU-BM",
    name: "ОУ Браќа Миладиновци",
    city: "Скопје",
    admin: { email: "admin@edu.mk", first_name: "Систем", last_name: "Администратор" },
    teachers: [
      { email: "email122@email.com", first_name: "Ана", last_name: "Трајковска", title: "Наставник по математика" },
      { email: "teacher2@edu.mk", first_name: "Петар", last_name: "Миленков", title: "Наставник по физика" },
      { email: "teacher4@edu.mk", first_name: "Јована", last_name: "Георгиева", title: "Наставник по македонски јазик" },
      { email: "teacher5@edu.mk", first_name: "Андреј", last_name: "Ристов", title: "Наставник по историја" }
    ],
    classrooms: [
      { name: "6-A", grade_level: "6", size: 15 },
      { name: "6-B", grade_level: "6", size: 15 },
      { name: "7-A", grade_level: "7", size: 15 },
      { name: "7-B", grade_level: "7", size: 15 }
    ],
    subjects: [
      { name: "Математика", code: "MAT-BM", teacher_index: 0 },
      { name: "Физика", code: "PHY-BM", teacher_index: 1 },
      { name: "Македонски јазик", code: "MKD-BM", teacher_index: 2 },
      { name: "Историја", code: "HIS-BM", teacher_index: 3 }
    ]
  },
  {
    code: "OU-KO",
    name: "ОУ Кочо Рацин",
    city: "Скопје",
    admin: { email: "admin.ko@edu.mk", first_name: "Марија", last_name: "Администратор" },
    teachers: [
      { email: "teacher3@edu.mk", first_name: "Елена", last_name: "Јовановска", title: "Наставник по биологија" },
      { email: "teacher6@edu.mk", first_name: "Никола", last_name: "Стефанов", title: "Наставник по хемија" },
      { email: "teacher7@edu.mk", first_name: "Тамара", last_name: "Петровска", title: "Наставник по англиски јазик" },
      { email: "teacher8@edu.mk", first_name: "Борис", last_name: "Митевски", title: "Наставник по географија" }
    ],
    classrooms: [
      { name: "8-A", grade_level: "8", size: 15 },
      { name: "8-B", grade_level: "8", size: 15 },
      { name: "9-A", grade_level: "9", size: 15 },
      { name: "9-B", grade_level: "9", size: 15 }
    ],
    subjects: [
      { name: "Биологија", code: "BIO-KO", teacher_index: 0 },
      { name: "Хемија", code: "CHE-KO", teacher_index: 1 },
      { name: "Англиски јазик", code: "ENG-KO", teacher_index: 2 },
      { name: "Географија", code: "GEO-KO", teacher_index: 3 }
    ]
  }
].freeze

assignment_templates = [
  {
    suffix: "Домашна задача 1",
    assignment_type: "homework",
    status: :published,
    due_days: 3,
    publish_days_ago: 4,
    max_points: 100,
    description: "Подгответе решенија и кратко образложение за секој чекор.",
    teacher_notes: "Прво прегледајте ги материјалите, а потоа решавајте по редослед.",
    content_json: [
      { type: "heading", text: "Упатство за задачата" },
      { type: "paragraph", text: "Прочитај ги материјалите и одговори со јасни реченици." },
      { type: "instruction", text: "Користи пример од лекцијата кога објаснуваш." }
    ],
    resources: [
      { title: "PDF упатство", resource_type: "pdf", file_url: "https://example.com/assignment-guide.pdf", description: "Главно упатство за задачата.", is_required: true },
      { title: "Видео објаснување", resource_type: "video", external_url: "https://example.com/video", description: "Кратко видео со објаснување.", is_required: false }
    ],
    steps: [
      { title: "Прочитај лекција", content: "Прегледај ја лекцијата и издвој ги клучните поими.", prompt: "Издвои 3 клучни поими од лекцијата.", resource_url: "https://example.com/lesson", example_answer: "Пример: поим 1, поим 2, поим 3", content_json: [{ type: "text", text: "Запиши ги поимите со кратко објаснување." }], step_type: "reading", required: true },
      { title: "Реши задача", content: "Реши го главниот проблем и објасни го пристапот.", prompt: "Опиши ги чекорите на решавање.", resource_url: "https://example.com/example-problem", example_answer: "Прво го читам условот, потоа ги запишувам податоците...", content_json: [{ type: "instruction", text: "Покажи ја логиката, не само конечниот одговор." }], step_type: "text", required: true },
      { title: "Кратка рефлексија", content: "Напиши што ти беше најтешко.", prompt: "Напиши 2-3 реченици за искуството.", resource_url: nil, example_answer: "Најтешко ми беше да го организирам одговорот.", content_json: [{ type: "quote", text: "Што научив од оваа задача?" }], step_type: "text", required: false }
    ]
  },
  {
    suffix: "Проектна активност",
    assignment_type: "project",
    status: :scheduled,
    due_days: 10,
    publish_days_ago: nil,
    max_points: 100,
    description: "Подгответе мини проект со истражување и презентација.",
    teacher_notes: "Фокусирајте се на структура и квалитет на извори.",
    content_json: [
      { type: "heading", text: "Проектна активност" },
      { type: "paragraph", text: "Изработете краток проект со јасна структура и заклучок." }
    ],
    resources: [
      { title: "Шаблон за презентација", resource_type: "file", file_url: "https://example.com/template.pptx", description: "Шаблон што може да се користи.", is_required: false }
    ],
    steps: [
      { title: "Истражување", content: "Собери најмалку три извори.", prompt: "Наведи ги изворите и зошто ги избра.", resource_url: "https://example.com/research-guide", example_answer: nil, content_json: [{ type: "list", items: ["Извор 1", "Извор 2", "Извор 3"] }], step_type: "research", required: true },
      { title: "Презентација", content: "Подготви структура за презентирање.", prompt: "Направи вовед, главен дел и заклучок.", resource_url: "https://example.com/presentation-guide", example_answer: "Слајд 1: тема, Слајд 2: главни идеи...", content_json: [{ type: "instruction", text: "Користи најмногу 6 слајдови." }], step_type: "upload", required: true },
      { title: "Самоевалуација", content: "Оцени го сопствениот напредок.", prompt: "Што би подобрил следниот пат?", resource_url: nil, example_answer: nil, content_json: [{ type: "text", text: "Кратка саморефлексија." }], step_type: "text", required: true }
    ]
  },
  {
    suffix: "Квиз за повторување",
    assignment_type: "quiz",
    status: :draft,
    due_days: 14,
    publish_days_ago: nil,
    max_points: 50,
    description: "Внатрешен квиз за повторување на материјалот.",
    teacher_notes: "Овој квиз е за вежбање и повторување.",
    content_json: [
      { type: "warning", text: "Одговори без помош од белешки." }
    ],
    resources: [
      { title: "Линк до белешки", resource_type: "link", external_url: "https://example.com/notes", description: "Материјал за повторување.", is_required: false }
    ],
    steps: [
      { title: "Прашања со избор", content: "Одговори на прашањата со избор.", prompt: "Избери го точниот одговор и објасни го.", resource_url: nil, example_answer: nil, content_json: [{ type: "text", text: "Прочитај внимателно пред да одговориш." }], step_type: "quiz", required: true },
      { title: "Краток одговор", content: "Објасни еден поим со свои зборови.", prompt: "Напиши кратко но прецизно објаснување.", resource_url: nil, example_answer: "Поимот значи...", content_json: [{ type: "hint", text: "Користи сопствени зборови." }], step_type: "text", required: true }
    ]
  }
]

seed_now = Time.zone.parse("2026-03-14 09:00:00")
academic_year = academic_year_for(Date.new(2026, 3, 14))

school_records = {}
teacher_records = {}
student_records = {}
classroom_records = {}
subject_records = {}

student_index = 0

SCHOOL_BLUEPRINTS.each do |blueprint|
  school = School.find_or_create_by!(code: blueprint[:code]) do |record|
    record.name = blueprint[:name]
    record.city = blueprint[:city]
    record.active = true
  end
  school.update!(name: blueprint[:name], city: blueprint[:city], active: true)
  school_records[blueprint[:code]] = school

  admin_data = blueprint[:admin]
  upsert_user(
    email: admin_data[:email],
    first_name: admin_data[:first_name],
    last_name: admin_data[:last_name],
    password: "password123",
    roles: %w[admin],
    school: school
  )

  teachers = blueprint[:teachers].map do |teacher_data|
    user = upsert_user(
      email: teacher_data[:email],
      first_name: teacher_data[:first_name],
      last_name: teacher_data[:last_name],
      password: "password123",
      roles: %w[teacher],
      school: school
    )

    upsert_teacher_profile(
      user: user,
      school: school,
      title: teacher_data[:title],
      bio: "#{teacher_data[:title]} во #{school.name}"
    )

    teacher_records[user.email] = user
    user
  end

  classrooms = blueprint[:classrooms].map.with_index do |classroom_data, index|
    classroom = upsert_classroom(
      school: school,
      name: classroom_data[:name],
      grade_level: classroom_data[:grade_level],
      academic_year: academic_year
    )

    homeroom_teacher = teachers[index % teachers.length]
    assign_teacher_to_classroom(teacher: homeroom_teacher, classroom: classroom, homeroom: true)
    assign_teacher_to_classroom(teacher: teachers[(index + 1) % teachers.length], classroom: classroom)
    classroom_records[[school.code, classroom.name]] = classroom
    classroom
  end

  subjects = blueprint[:subjects].map do |subject_data|
    subject = upsert_subject(
      school: school,
      name: subject_data[:name],
      code: subject_data[:code]
    )

    assign_teacher_to_subject(
      teacher: teachers.fetch(subject_data[:teacher_index]),
      subject: subject
    )
    subject_records[[school.code, subject.name]] = subject
    subject
  end

  blueprint[:classrooms].each_with_index do |classroom_data, classroom_index|
    classroom = classrooms.fetch(classroom_index)

    classroom_data[:size].times do
      if blueprint[:code] == "OU-BM" && classroom.name == "7-A" && student_index == 30
        email = "student1@edu.mk"
        first_name = "Марија"
        last_name = "Стојанова"
        student_number = "BM-7-001"
      elsif blueprint[:code] == "OU-BM" && classroom.name == "7-A" && student_index == 31
        email = "student2@edu.mk"
        first_name = "Иван"
        last_name = "Николов"
        student_number = "BM-7-002"
      elsif blueprint[:code] == "OU-KO" && classroom.name == "8-A" && student_index == 60
        email = "student3@edu.mk"
        first_name = "Сара"
        last_name = "Попова"
        student_number = "KO-8-001"
      elsif blueprint[:code] == "OU-BM" && classroom.name == "7-B" && student_index == 45
        email = "student4@edu.mk"
        first_name = "Давид"
        last_name = "Тодоров"
        student_number = "BM-7-003"
      elsif blueprint[:code] == "OU-KO" && classroom.name == "8-A" && student_index == 61
        email = "student5@edu.mk"
        first_name = "Ема"
        last_name = "Андоновска"
        student_number = "KO-8-002"
      else
        generated_index = student_index + 1
        first_name = FIRST_NAMES[student_index % FIRST_NAMES.length]
        last_name = LAST_NAMES[(student_index / FIRST_NAMES.length) % LAST_NAMES.length]
        email = format("student%03d@edu.mk", generated_index)
        student_number = "#{school.code.split('-').last}-#{classroom.grade_level}-#{format('%03d', generated_index)}"
      end

      student = upsert_user(
        email: email,
        first_name: first_name,
        last_name: last_name,
        password: "password123",
        roles: %w[student],
        school: school
      )

      upsert_student_profile(
        user: student,
        school: school,
        grade_level: classroom.grade_level,
        student_number: student_number,
        guardian_name: "Родител #{last_name}",
        guardian_phone: format("+38970%06d", 100000 + student_index)
      )

      assign_student_to_classroom(
        student: student,
        classroom: classroom,
        joined_at: seed_now - 180.days + student_index.days
      )

      student_records[student.email] = student
      student_index += 1
    end
  end

  subjects.each_with_index do |subject, subject_index|
    teacher = subject.teachers.first || teachers.fetch(subject_index % teachers.length)

    classrooms.each_with_index do |classroom, classroom_index|
      next unless classroom_index % subjects.length == subject_index % subjects.length

      assignment_templates.each_with_index do |template, template_index|
        due_at = seed_now + template[:due_days].days + classroom_index.days
        published_at = template[:publish_days_ago] ? seed_now - template[:publish_days_ago].days : nil
        assignment = upsert_assignment(
          classroom: classroom,
          subject: subject,
          teacher: teacher,
          title: "#{subject.name} - #{classroom.name} #{template[:suffix]}",
          description: template[:description],
          teacher_notes: template[:teacher_notes],
          content_json: template[:content_json],
          assignment_type: template[:assignment_type],
          status: template[:status],
          due_at: due_at,
          published_at: published_at,
          max_points: template[:max_points],
          settings: { difficulty: classroom.grade_level, template_key: template[:suffix].parameterize }
        )

        steps = template[:steps].map.with_index do |step_template, step_index|
          upsert_assignment_step(
            assignment: assignment,
            position: step_index + 1,
            title: step_template[:title],
            content: step_template[:content],
            prompt: step_template[:prompt],
            resource_url: step_template[:resource_url],
            example_answer: step_template[:example_answer],
            content_json: step_template[:content_json],
            step_type: step_template[:step_type],
            required: step_template[:required],
            metadata: { estimated_minutes: 10 + (step_index * 5) }
          )
        end

        template[:resources].each_with_index do |resource_template, resource_index|
          upsert_assignment_resource(
            assignment: assignment,
            title: resource_template[:title],
            resource_type: resource_template[:resource_type],
            file_url: resource_template[:file_url],
            external_url: resource_template[:external_url],
            embed_url: resource_template[:embed_url],
            description: resource_template[:description],
            position: resource_index + 1,
            is_required: resource_template[:is_required],
            metadata: { seeded: true }
          )
        end

        next unless assignment.published?

        classroom.students.order(:id).limit(6).each_with_index do |student, submission_index|
          scenario = submission_index % 4
          started_at = published_at ? published_at + (submission_index + 1).hours : seed_now - 1.day

          submission_attrs =
            case scenario
            when 0
              {
                status: :reviewed,
                submitted_at: started_at + 1.day,
                reviewed_at: started_at + 2.days,
                late: false,
                total_score: 92,
                feedback: "Одлична работа со прецизни објаснувања."
              }
            when 1
              {
                status: :submitted,
                submitted_at: started_at + 1.day,
                reviewed_at: nil,
                late: false,
                total_score: nil,
                feedback: nil
              }
            when 2
              {
                status: :in_progress,
                submitted_at: nil,
                reviewed_at: nil,
                late: false,
                total_score: nil,
                feedback: nil
              }
            else
              {
                status: :late,
                submitted_at: due_at + 1.day,
                reviewed_at: nil,
                late: true,
                total_score: nil,
                feedback: "Предадено по истекот на рокот."
              }
            end

          submission = upsert_submission(
            assignment: assignment,
            student: student,
            status: submission_attrs[:status],
            started_at: started_at,
            submitted_at: submission_attrs[:submitted_at],
            reviewed_at: submission_attrs[:reviewed_at],
            late: submission_attrs[:late],
            total_score: submission_attrs[:total_score],
            feedback: submission_attrs[:feedback]
          )

          steps.each_with_index do |step, answer_index|
            answer_status =
              if submission.reviewed?
                answer_index.even? ? :correct : :answered
              elsif submission.submitted? || submission.late?
                :answered
              else
                answer_index.zero? ? :answered : :unanswered
              end

            upsert_step_answer(
              submission: submission,
              assignment_step: step,
              answer_text: answer_status == :unanswered ? nil : "#{student.full_name} одговор за #{step.title.downcase}",
              answer_data: { autosaved: !submission.submitted? && !submission.reviewed?, word_count: 12 + answer_index },
              status: answer_status,
              answered_at: answer_status == :unanswered ? nil : started_at + (answer_index + 1).hours
            )
          end

          if submission.reviewed?
            grade = upsert_grade(
              submission: submission,
              teacher: teacher,
              score: 92 - template_index,
              max_score: assignment.max_points,
              feedback: "Одлично структурирано решение.",
              graded_at: submission.reviewed_at || (started_at + 2.days)
            )

            upsert_comment(
              author: teacher,
              commentable: grade,
              body: "Продолжи со вакво темпо."
            )

            upsert_notification(
              user: student,
              actor: teacher,
              notification_type: "grade_posted",
              title: "Оценка е објавена",
              body: assignment.title,
              payload: { grade_id: grade.id, submission_id: submission.id },
              read_at: seed_now - 1.day
            )
          elsif submission.submitted? || submission.late?
            upsert_notification(
              user: teacher,
              actor: student,
              notification_type: "submission_submitted",
              title: "Нова предадена задача",
              body: assignment.title,
              payload: { submission_id: submission.id, assignment_id: assignment.id }
            )
          end

          upsert_activity_log(
            user: student,
            action: "submission_#{submission.status}",
            trackable: submission,
            occurred_at: (submission.submitted_at || submission.started_at || seed_now),
            metadata: { assignment_id: assignment.id, classroom_id: classroom.id }
          )

          upsert_comment(
            author: student,
            commentable: submission,
            body: "Ми требаше малку повеќе време за оваа задача.",
            visibility: "teacher"
          ) if submission.in_progress?
        end

        event = upsert_calendar_event(
          school: school,
          assignment: assignment,
          title: "#{assignment.title} - рок",
          description: "Потсетник за рокот на задачата.",
          event_type: "assignment_due",
          starts_at: due_at,
          ends_at: due_at + 1.hour,
          all_day: false,
          metadata: { assignment_id: assignment.id, classroom_id: classroom.id }
        )

        upsert_event_participant(
          calendar_event: event,
          user: teacher,
          role: "teacher",
          attendance_status: "confirmed"
        )
        classroom.students.order(:id).limit(5).each do |student|
          upsert_event_participant(
            calendar_event: event,
            user: student,
            role: "student",
            attendance_status: "invited"
          )
        end

        upsert_comment(
          author: teacher,
          commentable: assignment,
          body: "Фокусирајте се на точност и јасно објаснување."
        )

        upsert_notification(
          user: teacher,
          actor: nil,
          notification_type: "assignment_summary",
          title: "Преглед на активност",
          body: assignment.title,
          payload: { assignment_id: assignment.id, pending_reviews: assignment.submissions.where(status: %i[submitted late]).count },
          read_at: seed_now - 2.hours
        )
      end
    end
  end

  next_school_event = upsert_calendar_event(
    school: school,
    title: "#{school.name} - Родителска средба",
    description: "Средба со родители и класни раководители.",
    event_type: "meeting",
    starts_at: seed_now + 7.days,
    ends_at: seed_now + 7.days + 2.hours,
    all_day: false,
    metadata: { audience: "parents" }
  )

  teachers.each do |teacher|
    upsert_event_participant(
      calendar_event: next_school_event,
      user: teacher,
      role: "teacher",
      attendance_status: "confirmed"
    )
  end

  school.school_users.includes(:user).limit(10).each do |membership|
    user = membership.user
    upsert_notification(
      user: user,
      actor: nil,
      notification_type: "school_event",
      title: "Настан во календар",
      body: next_school_event.title,
      payload: { calendar_event_id: next_school_event.id }
    )
  end
end

TeacherClassroom.includes(:classroom, :user).where(homeroom: true).find_each do |teacher_classroom|
  next unless teacher_classroom.classroom.school

  upsert_homeroom_assignment(
    school: teacher_classroom.classroom.school,
    classroom: teacher_classroom.classroom,
    teacher: teacher_classroom.user,
    starts_on: Date.new(2025, 9, 1)
  )
end

School.includes(:classrooms, :subjects, :users).find_each do |school|
  lead_teacher = school.users.joins(:roles).where(roles: { name: "teacher" }).order(:id).first
  next unless lead_teacher

  school_announcement = upsert_announcement(
    school: school,
    author: lead_teacher,
    title: "#{school.name} - Неделен план",
    body: "Проверете ги задачите, календарот и најавите за тековната недела.",
    audience_type: "school",
    status: :published,
    priority: :important,
    published_at: seed_now - 2.days,
    starts_at: seed_now - 2.days,
    ends_at: seed_now + 5.days
  )

  school.classrooms.order(:id).limit(2).each do |classroom|
    subject = school.subjects.order(:id).first
    teacher = classroom.teachers.order(:id).first || lead_teacher
    classroom_announcement = upsert_announcement(
      school: school,
      author: teacher,
      title: "#{classroom.name} - Подготовка за час",
      body: "Подгответе материјали и проверете ги известувањата во системот.",
      audience_type: "classroom",
      classroom: classroom,
      subject: subject,
      status: :published,
      priority: :normal,
      published_at: seed_now - 1.day,
      starts_at: seed_now - 1.day,
      ends_at: seed_now + 7.days
    )

    classroom.students.order(:id).limit(5).each do |student|
      upsert_notification(
        user: student,
        actor: teacher,
        notification_type: "announcement_published",
        title: classroom_announcement.title,
        body: classroom_announcement.body,
        payload: { announcement_id: classroom_announcement.id }
      )
    end

    classroom.students.order(:id).limit(5).each_with_index do |student, index|
      3.times do |day_offset|
        upsert_attendance_record(
          school: school,
          classroom: classroom,
          subject: subject,
          student: student,
          teacher: teacher,
          attendance_date: Date.current - day_offset,
          status: day_offset.zero? && index == 1 ? :late : :present,
          note: day_offset.zero? && index == 1 ? "Доцнеше 10 минути" : nil
        )
      end

      PerformanceSnapshots::GenerateForStudent.new(
        student: student,
        school: school,
        classroom: classroom,
        period_type: "monthly",
        date: Date.current
      ).call
    end
  end

  school.users.joins(:roles).where(roles: { name: "student" }).order(:id).limit(2).each do |student|
    assignment = student.submissions.includes(:assignment).order(:id).first&.assignment
    submission = student.submissions.order(:id).first
    subject = assignment&.subject || school.subjects.order(:id).first
    next unless subject

    ai_session = upsert_ai_session(
      school: school,
      user: student,
      assignment: assignment,
      submission: submission,
      subject: subject,
      title: "AI помош - #{subject.name}",
      session_type: :assignment_help,
      status: :active,
      started_at: seed_now - 6.hours,
      last_activity_at: seed_now - 1.hour,
      context_data: { focus: subject.name, language: "mk" }
    )

    upsert_ai_message(
      ai_session: ai_session,
      sequence_number: 1,
      role: :user,
      message_type: :question,
      content: "Може ли да ми помогнеш со оваа тема?",
      metadata: { source: "seed" }
    )
    upsert_ai_message(
      ai_session: ai_session,
      sequence_number: 2,
      role: :assistant,
      message_type: :hint,
      content: "Секако. Ајде прво да ги повториме клучните поими и потоа чекор по чекор да решиме пример.",
      metadata: { tone: "supportive" }
    )
  end

  upsert_comment(
    author: lead_teacher,
    commentable: school_announcement,
    body: "Следете ги известувањата редовно."
  )
end

puts "Seed data prepared:"
puts "- Schools: #{School.count}"
puts "- Users: #{User.count}"
puts "- Teachers: #{User.joins(:roles).where(roles: { name: 'teacher' }).distinct.count}"
puts "- Students: #{User.joins(:roles).where(roles: { name: 'student' }).distinct.count}"
puts "- Admins: #{User.joins(:roles).where(roles: { name: 'admin' }).distinct.count}"
puts "- Classrooms: #{Classroom.count}"
puts "- Subjects: #{Subject.count}"
puts "- Assignments: #{Assignment.count}"
puts "- Assignment steps: #{AssignmentStep.count}"
puts "- Submissions: #{Submission.count}"
puts "- Step answers: #{SubmissionStepAnswer.count}"
puts "- Grades: #{Grade.count}"
puts "- Comments: #{Comment.count}"
puts "- Calendar events: #{CalendarEvent.count}"
puts "- Event participants: #{EventParticipant.count}"
puts "- Notifications: #{Notification.count}"
puts "- Activity logs: #{ActivityLog.count}"
puts "- School users: #{SchoolUser.count}"
puts "- Teacher classrooms: #{TeacherClassroom.count}"
puts "- Classroom users (student enrollments): #{ClassroomUser.count}"
puts "- Teacher subjects: #{TeacherSubject.count}"

School.order(:id).each do |school|
  school_teacher_count = school.school_users
                             .joins(user: :roles)
                             .where(roles: { name: "teacher" })
                             .distinct
                             .count("school_users.user_id")
  school_student_count = school.school_users
                            .joins(user: :roles)
                            .where(roles: { name: "student" })
                            .distinct
                            .count("school_users.user_id")

  puts "  * #{school.name} (#{school.code}) -> teachers: #{school_teacher_count}, students: #{school_student_count}, classrooms: #{school.classrooms.count}"
end

puts "- Demo login (teacher): email122@email.com / password123"
puts "- Demo login (student): student1@edu.mk / password123"
puts "- Demo login (admin): admin@edu.mk / password123"
