require "test_helper"

class SchoolTest < ActiveSupport::TestCase
  test "name must be unique" do
    create_school(name: "Unique School Name", code: "UNQ-1")

    duplicate = School.new(name: "Unique School Name", code: "UNQ-2", city: "Скопје")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "code must be unique when present" do
    create_school(name: "First School", code: "UNQ-CODE")

    duplicate = School.new(name: "Second School", code: "UNQ-CODE", city: "Скопје")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:code], "has already been taken"
  end
end
