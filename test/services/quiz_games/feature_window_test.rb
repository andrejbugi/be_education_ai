require "test_helper"

class QuizGames::FeatureWindowTest < ActiveSupport::TestCase
  include ApiTestFactory

  test "blocked windows can disable availability inside a broader open window" do
    school = create_school
    school.update!(
      settings: {
        "quiz_games" => {
          "timezone" => "UTC",
          "available_from" => "08:00",
          "available_until" => "20:00",
          "blocked_windows" => [
            {
              "start_time" => "09:00",
              "end_time" => "15:00"
            }
          ]
        }
      }
    )

    travel_to Time.utc(2026, 3, 19, 10, 0, 0) do
      assert_not QuizGames::FeatureWindow.new(school: school).available_now?
    end

    travel_to Time.utc(2026, 3, 19, 18, 0, 0) do
      assert QuizGames::FeatureWindow.new(school: school).available_now?
    end
  end
end
