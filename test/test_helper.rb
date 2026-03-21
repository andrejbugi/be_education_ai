ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "tempfile"

if defined?(Rails::LineFiltering) && Minitest::Runnable.method(:run).arity == 3
  module Rails
    module LineFiltering
      def run(*args, **kwargs)
        return super(*args, **kwargs) if args.size == 3

        reporter, options = args
        options ||= {}
        options = options.merge(filter: Rails::TestUnit::Runner.compose_filter(self, options[:filter]))
        super(reporter, options, **kwargs)
      end
    end
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: 0)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module ApiAuthHelpers
  def auth_headers_for(user, school: nil)
    token = Auth::JwtToken.encode(
      {
        user_id: user.id,
        school_id: school&.id,
        role_names: user.roles.pluck(:name)
      }
    )
    headers = { "Authorization" => "Bearer #{token}" }
    headers["X-School-Id"] = school.id if school
    headers
  end
end

module ApiTestFactory
  def ensure_base_roles
    Role::BASE_ROLES.each { |name| Role.find_or_create_by!(name: name) }
  end

  def unique_value(prefix)
    @unique_value_counter ||= 0
    @unique_value_counter += 1
    "#{prefix}-#{@unique_value_counter}"
  end

  def create_school(active: true, name: nil, code: nil, city: "Скопје")
    School.create!(
      name: name || unique_value("School"),
      code: code || unique_value("SC"),
      city: city,
      active: active
    )
  end

  def create_user_with_roles(school:, roles:, email: nil, password: "password123", first_name: "Test", last_name: "User", active: true)
    ensure_base_roles

    user = User.create!(
      email: email || "#{unique_value('user')}@example.com",
      password: password,
      password_confirmation: password,
      first_name: first_name,
      last_name: last_name,
      active: active
    )

    roles.each do |role_name|
      UserRole.create!(user: user, role: Role.find_by!(name: role_name))
    end

    SchoolUser.create!(school: school, user: user)
    user
  end

  def create_teacher(school:, email: nil, first_name: "Teacher", last_name: "User")
    create_user_with_roles(
      school: school,
      roles: %w[teacher],
      email: email,
      first_name: first_name,
      last_name: last_name
    )
  end

  def create_student(school:, classroom: nil, email: nil, first_name: "Student", last_name: "User")
    student = create_user_with_roles(
      school: school,
      roles: %w[student],
      email: email,
      first_name: first_name,
      last_name: last_name
    )
    ClassroomUser.create!(classroom: classroom, user: student) if classroom
    student
  end

  def create_admin(school:, email: nil, first_name: "Admin", last_name: "User")
    create_user_with_roles(
      school: school,
      roles: %w[admin],
      email: email,
      first_name: first_name,
      last_name: last_name
    )
  end

  def create_classroom(school:, teacher: nil, name: nil, grade_level: "7", academic_year: "2025/2026")
    classroom = Classroom.create!(
      school: school,
      name: name || unique_value("7-A"),
      grade_level: grade_level,
      academic_year: academic_year
    )
    TeacherClassroom.create!(classroom: classroom, user: teacher) if teacher
    classroom
  end

  def create_subject(school:, teacher: nil, name: nil, code: nil)
    subject = Subject.create!(
      school: school,
      name: name || unique_value("Предмет"),
      code: code || unique_value("SUB")
    )
    TeacherSubject.create!(teacher: teacher, subject: subject) if teacher
    subject
  end

  def create_subject_topic(subject:, name: nil)
    SubjectTopic.create!(
      subject: subject,
      name: name || unique_value("Тема")
    )
  end

  def create_assignment(classroom:, subject:, teacher:, title: nil, subject_topic: nil, status: :published, due_at: 2.days.from_now, published_at: Time.current, teacher_notes: "Teacher notes", content_json: nil)
    Assignment.create!(
      classroom: classroom,
      subject: subject,
      teacher: teacher,
      title: title || unique_value("Задача"),
      subject_topic: subject_topic,
      description: "Опис",
      teacher_notes: teacher_notes,
      assignment_type: "homework",
      status: status,
      due_at: due_at,
      published_at: published_at,
      max_points: 100,
      content_json: content_json || [{ type: "instruction", text: "Прочитај ги упатствата внимателно." }]
    )
  end

  def create_assignment_step(assignment:, position: 1, title: nil, prompt: "Одговори на прашањето", resource_url: nil, example_answer: nil, content_json: nil, evaluation_mode: "manual", answer_keys: [])
    step = AssignmentStep.create!(
      assignment: assignment,
      position: position,
      title: title || "Чекор #{position}",
      content: "Содржина",
      prompt: prompt,
      resource_url: resource_url,
      example_answer: example_answer,
      step_type: "text",
      required: true,
      content_json: content_json || [{ type: "text", text: "Дополнително објаснување за чекорот." }],
      evaluation_mode: evaluation_mode
    )
    Array(answer_keys).each_with_index do |answer_key, index|
      create_assignment_step_answer_key(
        assignment_step: step,
        value: answer_key[:value] || answer_key["value"],
        position: answer_key[:position] || answer_key["position"] || (index + 1),
        tolerance: answer_key[:tolerance] || answer_key["tolerance"],
        case_sensitive: answer_key.key?(:case_sensitive) ? answer_key[:case_sensitive] : answer_key["case_sensitive"],
        metadata: answer_key[:metadata] || answer_key["metadata"] || {}
      )
    end
    step
  end

  def create_assignment_step_answer_key(assignment_step:, value:, position: 1, tolerance: nil, case_sensitive: false, metadata: {})
    AssignmentStepAnswerKey.create!(
      assignment_step: assignment_step,
      value: value,
      position: position,
      tolerance: tolerance,
      case_sensitive: case_sensitive.nil? ? false : case_sensitive,
      metadata: metadata
    )
  end

  def create_assignment_resource(assignment:, title: "Ресурс", resource_type: "link", position: 1, file_url: nil, external_url: "https://example.com", embed_url: nil, description: "Опис на ресурс", is_required: false)
    resource = AssignmentResource.new(
      assignment: assignment,
      title: title,
      resource_type: resource_type,
      position: position,
      file_url: file_url,
      external_url: external_url,
      embed_url: embed_url,
      description: description,
      is_required: is_required
    )
    yield resource if block_given?
    resource.save!
    resource
  end

  def uploaded_test_file(filename: "resource.txt", content_type: "text/plain", content: "Test resource file")
    @uploaded_tempfiles ||= []
    tempfile = Tempfile.new([File.basename(filename, ".*"), File.extname(filename)])
    tempfile.binmode
    tempfile.write(content)
    tempfile.rewind
    @uploaded_tempfiles << tempfile

    Rack::Test::UploadedFile.new(tempfile.path, content_type, true, original_filename: filename)
  end

  def create_submission(assignment:, student:, status: :submitted, started_at: 2.days.ago, submitted_at: 1.day.ago, reviewed_at: nil, total_score: nil, late: false)
    Submission.create!(
      assignment: assignment,
      student: student,
      status: status,
      started_at: started_at,
      submitted_at: submitted_at,
      reviewed_at: reviewed_at,
      total_score: total_score,
      late: late
    )
  end

  def create_grade(submission:, teacher:, score: 90, max_score: 100, feedback: "Одлично")
    Grade.create!(
      submission: submission,
      teacher: teacher,
      score: score,
      max_score: max_score,
      feedback: feedback,
      graded_at: Time.current
    )
  end

  def create_daily_quiz_question(school: nil, quiz_date: Date.current, title: "Квиз на денот", body: "Кој град е главен град на Македонија?", category: "geography", answer_type: "single_choice", correct_answer: "Скопје", answer_options: ["Битола", "Скопје", "Охрид"], explanation: "Скопје е главен град на Македонија.", is_active: true, created_by: nil)
    DailyQuizQuestion.create!(
      school: school,
      quiz_date: quiz_date,
      title: title,
      body: body,
      category: category,
      answer_type: answer_type,
      correct_answer: correct_answer,
      answer_options: answer_options,
      explanation: explanation,
      is_active: is_active,
      created_by: created_by
    )
  end

  def create_learning_game_config(school: nil, game_key:, title:, description: "Опис", icon_key: nil, is_enabled: true, position: 0, metadata: {})
    LearningGameConfig.create!(
      school: school,
      game_key: game_key,
      title: title,
      description: description,
      icon_key: icon_key,
      is_enabled: is_enabled,
      position: position,
      metadata: metadata
    )
  end
end

class ActionDispatch::IntegrationTest
  include ApiAuthHelpers
  include ApiTestFactory
end
