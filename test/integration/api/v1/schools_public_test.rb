require "test_helper"

class Api::V1::SchoolsPublicTest < ActionDispatch::IntegrationTest
  test "schools index is public and returns active schools" do
    active_school = School.create!(name: "ОУ Тест Активно", code: "OU-ACT", city: "Скопје", active: true)
    School.create!(name: "ОУ Тест Неактивно", code: "OU-INACT", city: "Скопје", active: false)

    get "/api/v1/schools"

    assert_response :success
    payload = JSON.parse(response.body)

    assert_equal 1, payload.size
    assert_equal active_school.id, payload.first["id"]
    assert_equal true, payload.first["active"]
  end
end
