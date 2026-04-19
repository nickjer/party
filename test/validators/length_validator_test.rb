# frozen_string_literal: true

require "test_helper"

class LengthValidatorTest < ActiveSupport::TestCase
  test "#error_for returns nil when length within bounds" do
    validator = LengthValidator.new(min: 3, max: 5, field: :name)

    assert_nil validator.error_for("abc")
    assert_nil validator.error_for("abcd")
    assert_nil validator.error_for("abcde")
  end

  test "#error_for returns too-short message when below minimum" do
    validator = LengthValidator.new(min: 3, max: 5, field: :name)

    assert_equal "is too short (minimum is 3 characters)",
      validator.error_for("ab")
  end

  test "#error_for returns too-long message when above maximum" do
    validator = LengthValidator.new(min: 3, max: 5, field: :name)

    assert_equal "is too long (maximum is 5 characters)",
      validator.error_for("abcdef")
  end

  test "#error_for works with any value that responds to length" do
    validator = LengthValidator.new(min: 3, max: 5, field: :name)
    normalized = NormalizedString.new("abcd")

    assert_nil validator.error_for(normalized)
  end

  test "#validate! returns nil when length within bounds" do
    validator = LengthValidator.new(min: 3, max: 5, field: :name)

    assert_nil validator.validate!("abcd")
  end

  test "#validate! raises ArgumentError when below minimum" do
    validator = LengthValidator.new(min: 3, max: 5, field: :name)

    error = assert_raises(ArgumentError) { validator.validate!("ab") }
    assert_equal "Name length must be between 3 and 5 characters", error.message
  end

  test "#validate! raises ArgumentError when above maximum" do
    validator = LengthValidator.new(min: 3, max: 5, field: :question)

    error = assert_raises(ArgumentError) { validator.validate!("abcdef") }
    assert_equal "Question length must be between 3 and 5 characters",
      error.message
  end

  test "#validate! humanizes field name in error message" do
    validator = LengthValidator.new(min: 3, max: 5, field: :player_name)

    error = assert_raises(ArgumentError) { validator.validate!("ab") }
    assert_match(/Player name length must be between/, error.message)
  end
end
