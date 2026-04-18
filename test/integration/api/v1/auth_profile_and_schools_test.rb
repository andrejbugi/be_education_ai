require "test_helper"

class Api::V1::AuthProfileAndSchoolsTest < ActionDispatch::IntegrationTest
  test "login rejects invalid password" do
    school = create_school
    user = create_teacher(school: school, email: "bad-login@example.com")

    post "/api/v1/auth/login", params: { email: user.email, password: "wrong-password" }

    assert_response :unauthorized
  end

  test "login rejects inactive user" do
    school = create_school
    user = create_teacher(school: school, email: "inactive-login@example.com")
    user.update!(active: false)

    post "/api/v1/auth/login", params: { email: user.email, password: "password123" }

    assert_response :unauthorized
  end

  test "login rejects invalid school context" do
    school = create_school(code: "AUTH-1")
    other_school = create_school(code: "AUTH-2")
    user = create_teacher(school: school, email: "school-context@example.com")

    post "/api/v1/auth/login", params: {
      email: user.email,
      password: "password123",
      school_id: other_school.id
    }

    assert_response :forbidden
  end

  test "admin can log in without school membership" do
    admin_role = Role.find_or_create_by!(name: "admin")
    admin = User.create!(
      email: "admin.no.school@example.com",
      password: "password123",
      password_confirmation: "password123",
      first_name: "Admin",
      last_name: "NoSchool",
      active: true
    )
    UserRole.create!(user: admin, role: admin_role)

    post "/api/v1/auth/login", params: {
      email: admin.email,
      password: "password123"
    }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal admin.id, body.dig("user", "id")
    assert_nil body["school"]

    get "/api/v1/auth/me"

    assert_response :success
    me = JSON.parse(response.body)
    assert_equal [], me["schools"]
    assert_nil me["current_school"]
  end

  test "admin login does not force current school when school id is omitted" do
    school = create_school(code: "ADMIN-AUTH")
    admin = create_admin(school: school, email: "admin.school.member@example.com")

    post "/api/v1/auth/login", params: {
      email: admin.email,
      password: "password123"
    }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal admin.id, body.dig("user", "id")
    assert_nil body["school"]

    get "/api/v1/auth/me"

    assert_response :success
    me = JSON.parse(response.body)
    assert_equal school.id, me["schools"].first["id"]
    assert_nil me["current_school"]
  end

  test "me requires authentication" do
    get "/api/v1/auth/me"

    assert_response :unauthorized
  end

  test "profile show returns teacher profile and roles" do
    school = create_school
    teacher = create_teacher(school: school, first_name: "Ана", last_name: "Трајковска")
    TeacherProfile.create!(user: teacher, school: school, title: "Наставник", bio: "Био", room_name: "Кабинет 12", room_label: "К12")

    get "/api/v1/profile", headers: auth_headers_for(teacher, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal ["teacher"], payload["roles"]
    assert_equal "Наставник", payload["teacher_profile"]["title"]
    assert_equal "Кабинет 12", payload["teacher_profile"]["room_name"]
    assert_equal(
      {
        "font_scale" => "md",
        "contrast_mode" => "default",
        "reading_font" => "default",
        "reduce_motion" => false
      },
      payload["accessibility"]
    )
  end

  test "profile update persists teacher profile changes" do
    school = create_school
    teacher = create_teacher(school: school)
    TeacherProfile.create!(user: teacher, school: school, title: "Старо", bio: "Старо био")

    patch "/api/v1/profile", params: {
      first_name: "Ново",
      teacher_profile: {
        title: "Наслов",
        bio: "Ново био",
        room_name: "Лабораторија",
        room_label: "Л1"
      }
    }, headers: auth_headers_for(teacher, school: school)

    assert_response :success
    teacher.reload
    assert_equal "Ново", teacher.first_name
    assert_equal "Наслов", teacher.teacher_profile.title
    assert_equal "Лабораторија", teacher.teacher_profile.room_name
  end

  test "profile update persists accessibility preferences and keeps unspecified defaults" do
    school = create_school
    teacher = create_teacher(school: school)

    patch "/api/v1/profile", params: {
      accessibility: {
        font_scale: "lg",
        contrast_mode: "high"
      }
    }, headers: auth_headers_for(teacher, school: school)

    assert_response :success

    payload = JSON.parse(response.body)
    assert_equal "lg", payload.dig("accessibility", "font_scale")
    assert_equal "high", payload.dig("accessibility", "contrast_mode")
    assert_equal "default", payload.dig("accessibility", "reading_font")
    assert_equal false, payload.dig("accessibility", "reduce_motion")

    teacher.reload
    assert_equal(
      {
        "font_scale" => "lg",
        "contrast_mode" => "high",
        "reading_font" => "default",
        "reduce_motion" => false
      },
      teacher.accessibility_settings
    )
  end

  test "profile update rejects invalid accessibility preference values" do
    school = create_school
    teacher = create_teacher(school: school)

    patch "/api/v1/profile", params: {
      accessibility: {
        font_scale: "xxl",
        reduce_motion: "sometimes"
      }
    }, headers: auth_headers_for(teacher, school: school)

    assert_response :unprocessable_entity
    payload = JSON.parse(response.body)
    assert_includes payload["errors"], "Settings accessibility font_scale is invalid"
    assert_includes payload["errors"], "Settings accessibility reduce_motion must be true or false"
  end

  test "profile update persists student profile changes" do
    school = create_school
    classroom = create_classroom(school: school)
    student = create_student(school: school, classroom: classroom)
    StudentProfile.create!(user: student, school: school, grade_level: "7", student_number: "S-1")

    patch "/api/v1/profile", params: {
      locale: "en",
      student_profile: {
        guardian_name: "Parent Name",
        guardian_phone: "+38970123456"
      }
    }, headers: auth_headers_for(student, school: school)

    assert_response :success
    student.reload
    assert_equal "en", student.locale
    assert_equal "Parent Name", student.student_profile.guardian_name
  end

  test "profile update ignores unpermitted email field" do
    school = create_school
    teacher = create_teacher(school: school, email: "teacher-one@example.com")
    create_teacher(school: school, email: "teacher-two@example.com")

    patch "/api/v1/profile", params: { first_name: "Updated", email: "teacher-two@example.com" }, headers: auth_headers_for(teacher, school: school)

    assert_response :success
    assert_equal "Updated", teacher.reload.first_name
    assert_equal "teacher-one@example.com", teacher.email
  end

  test "schools show returns classrooms and subjects for member" do
    school = create_school(code: "SHOW-SCHOOL")
    teacher = create_teacher(school: school)
    create_classroom(school: school, teacher: teacher, name: "8-A")
    create_subject(school: school, teacher: teacher, name: "Математика")

    get "/api/v1/schools/#{school.id}", headers: auth_headers_for(teacher, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal "SHOW-SCHOOL", payload["code"]
    assert_equal 1, payload["classrooms"].length
    assert_equal 1, payload["subjects"].length
  end

  test "schools show returns not found for non member" do
    school = create_school
    other_school = create_school
    teacher = create_teacher(school: school)

    get "/api/v1/schools/#{other_school.id}", headers: auth_headers_for(teacher, school: school)

    assert_response :not_found
  end
end
