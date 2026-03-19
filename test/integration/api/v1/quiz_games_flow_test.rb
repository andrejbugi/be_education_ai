require "test_helper"

class Api::V1::QuizGamesFlowTest < ActionDispatch::IntegrationTest
  test "student can fetch and answer today's quiz once with xp reward" do
    travel_to Time.utc(2026, 3, 19, 18, 30, 0) do
      school = create_school
      school.update!(settings: quiz_games_settings("18:00", "20:00"))
      student = create_student(school: school)
      question = create_daily_quiz_question(school: school, quiz_date: Date.current)

      get "/api/v1/student/daily_quiz", headers: auth_headers_for(student, school: school)

      assert_response :success
      payload = JSON.parse(response.body)
      assert_equal "2026-03-19", payload["date"]
      assert_equal true, payload["available_now"]
      assert_equal false, payload["already_answered"]
      assert_equal question.id, payload.dig("question", "id")
      assert_equal 1, payload.dig("reward", "correct_xp")

      post "/api/v1/student/daily_quiz/answer",
           params: {
             daily_quiz_question_id: question.id,
             selected_answer: "Скопје"
           },
           headers: auth_headers_for(student, school: school),
           as: :json

      assert_response :created
      answer_payload = JSON.parse(response.body)
      assert_equal true, answer_payload["correct"]
      assert_equal 1, answer_payload["xp_awarded"]
      assert_equal true, answer_payload["already_answered"]
      assert_equal "Скопје е главен град на Македонија.", answer_payload["explanation"]
      assert_equal 1, DailyQuizAnswer.count
      assert_equal 1, StudentRewardEvent.count
      assert_equal 1, StudentProgressProfile.find_by!(school: school, student: student).total_xp

      post "/api/v1/student/daily_quiz/answer",
           params: {
             daily_quiz_question_id: question.id,
             selected_answer: "Скопје"
           },
           headers: auth_headers_for(student, school: school),
           as: :json

      assert_response :success
      duplicate_payload = JSON.parse(response.body)
      assert_equal true, duplicate_payload["correct"]
      assert_equal 1, duplicate_payload["xp_awarded"]
      assert_equal 1, DailyQuizAnswer.count
      assert_equal 1, StudentRewardEvent.count

      get "/api/v1/student/daily_quiz", headers: auth_headers_for(student, school: school)

      assert_response :success
      refreshed_payload = JSON.parse(response.body)
      assert_equal true, refreshed_payload["already_answered"]
      assert_equal true, refreshed_payload.dig("answer", "correct")
      assert_equal 1, refreshed_payload.dig("answer", "xp_awarded")
    end
  end

  test "student can submit a daily quiz outside the learning games availability window" do
    travel_to Time.utc(2026, 3, 19, 15, 0, 0) do
      school = create_school
      school.update!(settings: quiz_games_settings("18:00", "20:00"))
      student = create_student(school: school)
      question = create_daily_quiz_question(school: school, quiz_date: Date.current)

      get "/api/v1/student/daily_quiz", headers: auth_headers_for(student, school: school)

      assert_response :success
      payload = JSON.parse(response.body)
      assert_equal true, payload["available_now"]
      assert_equal "00:00", payload["available_from"]
      assert_equal "23:59", payload["available_until"]
      assert_equal question.id, payload.dig("question", "id")

      post "/api/v1/student/daily_quiz/answer",
           params: {
             daily_quiz_question_id: question.id,
             selected_answer: "Скопје"
           },
           headers: auth_headers_for(student, school: school),
           as: :json

      assert_response :created
      assert_equal 1, DailyQuizAnswer.count
      assert_equal 1, StudentRewardEvent.count
    end
  end

  test "learning games endpoint is locked outside the configured timeframe" do
    travel_to Time.utc(2026, 3, 19, 15, 0, 0) do
      school = create_school
      school.update!(settings: quiz_games_settings("18:00", "20:00"))
      student = create_student(school: school)

      create_learning_game_config(
        game_key: "geometry_shapes",
        title: "Геометрија",
        description: "Препознај форми и агли.",
        position: 1
      )

      get "/api/v1/student/learning_games", headers: auth_headers_for(student, school: school)

      assert_response :success
      payload = JSON.parse(response.body)
      assert_equal false, payload["available_now"]
      assert_equal "18:00", payload["available_from"]
      assert_equal "20:00", payload["available_until"]
      assert_equal 1, payload["games"].length
    end
  end

  test "learning games endpoint returns enabled catalog with school overrides" do
    travel_to Time.utc(2026, 3, 19, 18, 30, 0) do
      school = create_school
      school.update!(settings: quiz_games_settings("18:00", "20:00"))
      student = create_student(school: school)

      create_learning_game_config(
        game_key: "geometry_shapes",
        title: "Глобална геометрија",
        position: 5
      )
      create_learning_game_config(
        school: school,
        game_key: "geometry_shapes",
        title: "Геометрија",
        description: "Препознај форми и агли.",
        position: 1
      )
      create_learning_game_config(
        game_key: "basic_math_speed",
        title: "Брза математика",
        description: "Решавај кратки математички задачи.",
        position: 2
      )
      create_learning_game_config(
        school: school,
        game_key: "memory_pairs",
        title: "Меморија",
        is_enabled: false,
        position: 3
      )

      get "/api/v1/student/learning_games", headers: auth_headers_for(student, school: school)

      assert_response :success
      payload = JSON.parse(response.body)
      assert_equal true, payload["available_now"]
      assert_equal ["geometry_shapes", "basic_math_speed"], payload["games"].map { |game| game["game_key"] }
      assert_equal "Геометрија", payload["games"].first["title"]
      assert_equal "Препознај форми и агли.", payload["games"].first["description"]
    end
  end

  private

  def quiz_games_settings(available_from, available_until)
    {
      "quiz_games" => {
        "timezone" => "UTC",
        "available_from" => available_from,
        "available_until" => available_until
      }
    }
  end
end
