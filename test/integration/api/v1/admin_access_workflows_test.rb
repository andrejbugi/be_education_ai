require "test_helper"

class Api::V1::AdminAccessWorkflowsTest < ActionDispatch::IntegrationTest
  setup do
    ActionMailer::Base.deliveries.clear
  end

  test "non admin cannot access admin endpoints" do
    school = create_school
    teacher = create_teacher(school: school)

    get "/api/v1/admin/schools", headers: auth_headers_for(teacher)

    assert_response :forbidden
  end

  test "school bound admin endpoints require current school" do
    school = create_school
    admin = create_admin(school: school)

    get "/api/v1/admin/teachers", headers: auth_headers_for(admin)

    assert_response :forbidden
  end

  test "admin can create update deactivate and reactivate school" do
    school = create_school
    admin = create_admin(school: school)

    post "/api/v1/admin/schools",
         params: { name: "Ново училиште", code: "NU-1", city: "Битола", settings: { feature_flag: true } },
         headers: auth_headers_for(admin)

    assert_response :created
    payload = JSON.parse(response.body)
    created_school = School.find(payload["id"])
    assert_equal "Ново училиште", created_school.name
    assert current_school_ids_for(admin).include?(created_school.id)

    patch "/api/v1/admin/schools/#{created_school.id}",
          params: { city: "Охрид" },
          headers: auth_headers_for(admin)

    assert_response :success
    assert_equal "Охрид", created_school.reload.city

    post "/api/v1/admin/schools/#{created_school.id}/deactivate", headers: auth_headers_for(admin)
    assert_response :success
    assert_equal false, created_school.reload.active

    post "/api/v1/admin/schools/#{created_school.id}/reactivate", headers: auth_headers_for(admin)
    assert_response :success
    assert_equal true, created_school.reload.active
  end

  test "admin can invite teacher and manage teacher memberships" do
    school = create_school
    admin = create_admin(school: school)
    subject = create_subject(school: school)
    classroom = create_classroom(school: school)

    post "/api/v1/admin/teachers",
         params: {
           email: "teacher.invited@example.com",
           first_name: "Ивана",
           last_name: "Наставник",
           teacher_profile: { title: "Проф.", bio: "Математика", room_name: "Кабинет математика", room_label: "М-1" }
         },
         headers: auth_headers_for(admin, school: school)

    assert_response :created
    payload = JSON.parse(response.body)
    teacher = User.find(payload["id"])
    invitation = UserInvitation.find_by!(user: teacher, school: school, role_name: "teacher")

    assert_equal false, teacher.active
    assert_equal "pending", invitation.status
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal "pending", payload["invitation_status"]
    assert_equal "Кабинет математика", payload.dig("teacher_profile", "room_name")

    put "/api/v1/admin/teachers/#{teacher.id}/subjects",
        params: { subject_ids: [subject.id] },
        headers: auth_headers_for(admin, school: school)

    assert_response :success
    assert_equal [subject.id], teacher.reload.subjects.where(school_id: school.id).pluck(:id)

    put "/api/v1/admin/teachers/#{teacher.id}/classrooms",
        params: { classroom_ids: [classroom.id] },
        headers: auth_headers_for(admin, school: school)

    assert_response :success
    assert_equal [classroom.id], teacher.reload.teaching_classrooms.where(school_id: school.id).pluck(:id)

    post "/api/v1/admin/teachers/#{teacher.id}/resend_invitation",
         headers: auth_headers_for(admin, school: school)

    assert_response :success
    assert_equal 2, ActionMailer::Base.deliveries.size

    post "/api/v1/admin/teachers/#{teacher.id}/deactivate",
         headers: auth_headers_for(admin, school: school)

    assert_response :success
    assert_equal false, teacher.reload.active
    assert_equal "revoked", invitation.reload.status
    assert_not SchoolUser.exists?(school: school, user: teacher)
    assert_equal [], teacher.subjects.where(school_id: school.id).pluck(:id)
    assert_equal [], teacher.teaching_classrooms.where(school_id: school.id).pluck(:id)
  end

  test "admin can invite an existing teacher into another school without duplicating the account" do
    primary_school = create_school(code: "PRIMARY")
    invited_school = create_school(code: "INVITED")
    invited_school_admin = create_admin(school: invited_school, email: "admin.invited.school@example.com")
    teacher = create_teacher(school: primary_school, email: "shared.teacher@example.com", first_name: "Shared", last_name: "Teacher")
    TeacherProfile.create!(user: teacher, school: primary_school, title: "Existing title", bio: "Existing bio")

    user_count_before = User.count

    post "/api/v1/admin/teachers",
         params: {
           email: teacher.email,
           first_name: "Changed",
           last_name: "Name",
           teacher_profile: { title: "New title", bio: "New bio" }
         },
         headers: auth_headers_for(invited_school_admin, school: invited_school)

    assert_response :created
    payload = JSON.parse(response.body)
    invitation = UserInvitation.find_by!(user: teacher, school: invited_school, role_name: "teacher")

    assert_equal user_count_before, User.count
    assert_equal teacher.id, payload["id"]
    assert_equal "pending", payload["invitation_status"]
    assert_equal false, payload["active"]
    assert_not SchoolUser.exists?(school: invited_school, user: teacher)
    assert_equal "Existing title", teacher.reload.teacher_profile.title

    get "/api/v1/admin/teachers",
        headers: auth_headers_for(invited_school_admin, school: invited_school)

    assert_response :success
    listed_ids = JSON.parse(response.body).map { |row| row["id"] }
    assert_includes listed_ids, teacher.id

    post "/api/v1/auth/login", params: {
      email: teacher.email,
      password: "password123",
      school_id: invited_school.id
    }

    assert_response :forbidden

    post "/api/v1/invitations/#{extract_invitation_token(ActionMailer::Base.deliveries.last)}/accept",
         params: {
           first_name: "Shared",
           last_name: "Teacher",
           password: "new-password-should-be-ignored",
           password_confirmation: "new-password-should-be-ignored"
         }

    assert_response :success
    assert SchoolUser.exists?(school: invited_school, user: teacher)
    assert_equal "accepted", invitation.reload.status
    assert teacher.reload.authenticate("password123")
    assert_not teacher.authenticate("new-password-should-be-ignored")

    post "/api/v1/auth/login", params: {
      email: teacher.email,
      password: "password123",
      school_id: invited_school.id
    }

    assert_response :success
  end

  test "teacher deactivation only removes access for the selected school" do
    home_school = create_school(code: "HOME")
    removed_school = create_school(code: "REMOVED")
    removed_school_admin = create_admin(school: removed_school, email: "admin.removed.school@example.com")
    teacher = create_teacher(school: home_school, email: "multi.school.teacher@example.com")
    subject = create_subject(school: removed_school)
    classroom = create_classroom(school: removed_school)

    SchoolUser.create!(school: removed_school, user: teacher)
    TeacherSubject.create!(teacher: teacher, subject: subject)
    TeacherClassroom.create!(classroom: classroom, user: teacher)
    create_user_invitation(
      user: teacher,
      school: removed_school,
      invited_by: removed_school_admin,
      role_name: "teacher",
      status: :accepted,
      accepted_at: Time.current
    )

    post "/api/v1/admin/teachers/#{teacher.id}/deactivate",
         headers: auth_headers_for(removed_school_admin, school: removed_school)

    assert_response :success
    assert_equal true, teacher.reload.active
    assert SchoolUser.exists?(school: home_school, user: teacher)
    assert_not SchoolUser.exists?(school: removed_school, user: teacher)
    assert_equal "revoked", UserInvitation.find_by!(user: teacher, school: removed_school, role_name: "teacher").reload.status
    assert_equal [], teacher.subjects.where(school_id: removed_school.id).pluck(:id)
    assert_equal [], teacher.teaching_classrooms.where(school_id: removed_school.id).pluck(:id)

    post "/api/v1/auth/login", params: {
      email: teacher.email,
      password: "password123",
      school_id: removed_school.id
    }

    assert_response :forbidden

    post "/api/v1/auth/login", params: {
      email: teacher.email,
      password: "password123",
      school_id: home_school.id
    }

    assert_response :success
  end

  test "admin can invite student update student and assign classrooms" do
    school = create_school
    admin = create_admin(school: school)
    classroom = create_classroom(school: school)

    post "/api/v1/admin/students",
         params: {
           email: "student.invited@example.com",
           first_name: "Петар",
           last_name: "Ученик",
           student_profile: { grade_level: "7", guardian_name: "Родител", guardian_phone: "070123123" }
         },
         headers: auth_headers_for(admin, school: school)

    assert_response :created
    student = User.find(JSON.parse(response.body)["id"])

    patch "/api/v1/admin/students/#{student.id}",
          params: { first_name: "Петко", student_profile: { student_number: "ST-77" } },
          headers: auth_headers_for(admin, school: school)

    assert_response :success
    assert_equal "Петко", student.reload.first_name
    assert_equal "ST-77", student.student_profile.student_number

    put "/api/v1/admin/students/#{student.id}/classrooms",
        params: { classroom_ids: [classroom.id] },
        headers: auth_headers_for(admin, school: school)

    assert_response :success
    assert_equal [classroom.id], student.reload.student_classrooms.where(school_id: school.id).pluck(:id)
  end

  test "public invitation show and accept activates invited user" do
    school = create_school
    admin = create_admin(school: school)

    post "/api/v1/admin/students",
         params: { email: "accept.student@example.com", first_name: "Елена", last_name: "Прием" },
         headers: auth_headers_for(admin, school: school)

    assert_response :created
    email = ActionMailer::Base.deliveries.last
    token = extract_invitation_token(email)

    get "/api/v1/invitations/#{token}"

    assert_response :success
    show_payload = JSON.parse(response.body)
    assert_equal "pending", show_payload["status"]
    assert_equal true, show_payload["accept_allowed"]

    post "/api/v1/invitations/#{token}/accept",
         params: {
           first_name: "Елена",
           last_name: "Прием",
           password: "password123",
           password_confirmation: "password123"
         }

    assert_response :success
    student = User.find_by!(email: "accept.student@example.com")
    invitation = UserInvitation.find_by!(user: student, school: school, role_name: "student")
    assert_equal true, student.reload.active
    assert_equal "accepted", invitation.reload.status
  end

  test "reused invitation token is rejected" do
    school = create_school
    admin = create_admin(school: school)
    user = create_user_with_roles(school: school, roles: %w[teacher], email: "reuse@example.com", active: false)
    invitation, token = create_user_invitation(user: user, school: school, invited_by: admin, role_name: "teacher")

    post "/api/v1/invitations/#{token}/accept",
         params: { password: "password123", password_confirmation: "password123" }

    assert_response :success
    assert_equal "accepted", invitation.reload.status

    post "/api/v1/invitations/#{token}/accept",
         params: { password: "password123", password_confirmation: "password123" }

    assert_response :unprocessable_entity
  end

  test "expired invitation is rejected" do
    school = create_school
    admin = create_admin(school: school)
    user = create_user_with_roles(school: school, roles: %w[student], email: "expired@example.com", active: false)
    invitation, token = create_user_invitation(user: user, school: school, invited_by: admin, role_name: "student", expires_at: 1.day.ago)

    get "/api/v1/invitations/#{token}"

    assert_response :success
    assert_equal "expired", JSON.parse(response.body)["status"]

    post "/api/v1/invitations/#{token}/accept",
         params: { password: "password123", password_confirmation: "password123" }

    assert_response :unprocessable_entity
    assert_equal "expired", invitation.reload.status
  end

  test "admin teachers list supports q and invitation status filter" do
    school = create_school
    admin = create_admin(school: school)
    pending_teacher = create_user_with_roles(school: school, roles: %w[teacher], email: "pending.filter@example.com", active: false, first_name: "Pending")
    accepted_teacher = create_teacher(school: school, email: "accepted.filter@example.com", first_name: "Accepted")
    create_user_invitation(user: pending_teacher, school: school, invited_by: admin, role_name: "teacher")

    get "/api/v1/admin/teachers",
        params: { q: "pending", invitation_status: "pending" },
        headers: auth_headers_for(admin, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal 1, payload.length
    assert_equal pending_teacher.id, payload.first["id"]
    assert_not_equal accepted_teacher.id, payload.first["id"]
  end

  test "admin can create update and delete classroom when safe" do
    school = create_school
    admin = create_admin(school: school)

    post "/api/v1/admin/classrooms",
         params: { name: "8-А", grade_level: "8", academic_year: "2026/2027", room_name: "Матична училница", room_label: "У8" },
         headers: auth_headers_for(admin, school: school)

    assert_response :created
    classroom = Classroom.find(JSON.parse(response.body)["id"])

    patch "/api/v1/admin/classrooms/#{classroom.id}",
          params: { name: "8-Б", room_label: "У9" },
          headers: auth_headers_for(admin, school: school)

    assert_response :success
    assert_equal "8-Б", classroom.reload.name
    assert_equal "У9", classroom.room_label

    delete "/api/v1/admin/classrooms/#{classroom.id}",
           headers: auth_headers_for(admin, school: school)

    assert_response :no_content
    assert_nil Classroom.find_by(id: classroom.id)
  end

  test "admin cannot delete classroom with blocking data" do
    school = create_school
    admin = create_admin(school: school)
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    create_assignment(classroom: classroom, subject: subject, teacher: teacher)

    delete "/api/v1/admin/classrooms/#{classroom.id}",
           headers: auth_headers_for(admin, school: school)

    assert_response :unprocessable_entity
    payload = JSON.parse(response.body)
    assert payload["blockers"]["assignments"].positive?
  end

  test "admin can create update and delete subject when safe" do
    school = create_school
    admin = create_admin(school: school)

    post "/api/v1/admin/subjects",
         params: { name: "Физика", code: "PHY-7", room_name: "Лабораторија физика", room_label: "Ф1" },
         headers: auth_headers_for(admin, school: school)

    assert_response :created
    subject = Subject.find(JSON.parse(response.body)["id"])

    patch "/api/v1/admin/subjects/#{subject.id}",
          params: { code: "PHY-8", room_label: "Ф2" },
          headers: auth_headers_for(admin, school: school)

    assert_response :success
    assert_equal "PHY-8", subject.reload.code
    assert_equal "Ф2", subject.room_label

    delete "/api/v1/admin/subjects/#{subject.id}",
           headers: auth_headers_for(admin, school: school)

    assert_response :no_content
    assert_nil Subject.find_by(id: subject.id)
  end

  test "admin cannot delete subject with blocking data" do
    school = create_school
    admin = create_admin(school: school)
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    create_assignment(classroom: classroom, subject: subject, teacher: teacher)

    delete "/api/v1/admin/subjects/#{subject.id}",
           headers: auth_headers_for(admin, school: school)

    assert_response :unprocessable_entity
    payload = JSON.parse(response.body)
    assert payload["blockers"]["assignments"].positive?
  end

  test "admin membership sync rejects ids from another school" do
    school = create_school
    other_school = create_school
    admin = create_admin(school: school)
    teacher = create_teacher(school: school)
    foreign_subject = create_subject(school: other_school)

    put "/api/v1/admin/teachers/#{teacher.id}/subjects",
        params: { subject_ids: [foreign_subject.id] },
        headers: auth_headers_for(admin, school: school)

    assert_response :unprocessable_entity
  end

  test "admin can manage a repeating weekly classroom schedule with room fallbacks" do
    school = create_school(code: "SCHEDULE")
    admin = create_admin(school: school)
    lead_teacher = create_teacher(school: school, email: "lead.schedule@example.com", first_name: "Лидија", last_name: "Професор")
    moving_teacher = create_teacher(school: school, email: "moving.schedule@example.com", first_name: "Борис", last_name: "Професор")
    TeacherProfile.create!(user: lead_teacher, school: school, title: "Проф.", room_name: "Кабинет историја", room_label: "И-2")
    TeacherProfile.create!(user: moving_teacher, school: school, title: "Проф.")
    classroom = create_classroom(school: school, teacher: lead_teacher, name: "II-3", grade_level: "II", academic_year: "2026/2027", room_name: "Матична училница II-3", room_label: "У-14")
    TeacherClassroom.create!(classroom: classroom, user: moving_teacher)
    subject_with_room = create_subject(school: school, teacher: lead_teacher, name: "Математика", room_name: "Кабинет математика", room_label: "М-3")
    subject_with_teacher_room = create_subject(school: school, teacher: lead_teacher, name: "Историја")
    subject_with_classroom_room = create_subject(school: school, teacher: moving_teacher, name: "Македонски")

    put "/api/v1/admin/classrooms/#{classroom.id}/schedule",
        params: {
          slots: [
            { day_of_week: "monday", period_number: 1, subject_id: subject_with_room.id, teacher_id: lead_teacher.id },
            { day_of_week: "monday", period_number: 2, subject_id: subject_with_teacher_room.id, teacher_id: lead_teacher.id },
            { day_of_week: "monday", period_number: 3, subject_id: subject_with_classroom_room.id, teacher_id: moving_teacher.id },
            { day_of_week: "monday", period_number: 4, subject_id: subject_with_classroom_room.id, teacher_id: moving_teacher.id, room_name: "Сала", room_label: "СП" }
          ]
        },
        headers: auth_headers_for(admin, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal 4, payload["slots"].length
    assert_equal "Кабинет математика", payload["slots"][0]["display_room_name"]
    assert_equal "subject_default", payload["slots"][0]["display_room_source"]
    assert_equal "Кабинет историја", payload["slots"][1]["display_room_name"]
    assert_equal "teacher_default", payload["slots"][1]["display_room_source"]
    assert_equal "Матична училница II-3", payload["slots"][2]["display_room_name"]
    assert_equal "classroom_default", payload["slots"][2]["display_room_source"]
    assert_equal "Сала", payload["slots"][3]["display_room_name"]
    assert_equal "slot", payload["slots"][3]["display_room_source"]
    assert_equal 3, payload["available_subjects"].length
    assert_equal 2, payload["available_teachers"].length

    get "/api/v1/admin/classrooms/#{classroom.id}/schedule",
        headers: auth_headers_for(admin, school: school)

    assert_response :success
    persisted_payload = JSON.parse(response.body)
    assert_equal [1, 2, 3, 4], persisted_payload["slots"].map { |slot| slot["period_number"] }
  end

  private

  def current_school_ids_for(user)
    user.schools.pluck(:id)
  end
end
