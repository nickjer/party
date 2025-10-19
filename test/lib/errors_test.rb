# frozen_string_literal: true

require "test_helper"

class ErrorsTest < ActiveSupport::TestCase
  # Errors::Error tests

  test "Error#initialize stores attribute and message" do
    error = Errors::Error.new(attribute: :name, message: "can't be blank")

    assert_equal :name, error.attribute
    assert_equal "can't be blank", error.message
  end

  test "Error#initialize converts attribute to symbol" do
    error = Errors::Error.new(attribute: "name", message: "can't be blank")

    assert_equal :name, error.attribute
  end

  test "Error#initialize converts message to string" do
    error = Errors::Error.new(attribute: :name, message: 123)

    assert_equal "123", error.message
  end

  test "Error#full_message returns humanized attribute and message" do
    error = Errors::Error.new(attribute: :first_name, message: "can't be blank")

    assert_equal "First name can't be blank", error.full_message
  end

  test "Error#full_message returns just message when attribute is :base" do
    error = Errors::Error.new(attribute: :base, message: "Something went wrong")

    assert_equal "Something went wrong", error.full_message
  end

  test "Error#to_s returns full_message" do
    error = Errors::Error.new(attribute: :name, message: "is invalid")

    assert_equal error.full_message, error.to_s
    assert_equal "Name is invalid", error.to_s
  end

  test "Error#== returns true for errors with same attribute and message" do
    error1 = Errors::Error.new(attribute: :name, message: "can't be blank")
    error2 = Errors::Error.new(attribute: :name, message: "can't be blank")

    assert_equal error1, error2
  end

  test "Error#== returns false for errors with different attributes" do
    error1 = Errors::Error.new(attribute: :name, message: "can't be blank")
    error2 = Errors::Error.new(attribute: :email, message: "can't be blank")

    assert_not_equal error1, error2
  end

  test "Error#== returns false for errors with different messages" do
    error1 = Errors::Error.new(attribute: :name, message: "can't be blank")
    error2 = Errors::Error.new(attribute: :name, message: "is invalid")

    assert_not_equal error1, error2
  end

  test "Error#== returns false when comparing with non-Error object" do
    error = Errors::Error.new(attribute: :name, message: "can't be blank")

    assert_not_equal error, "not an error"
    assert_not_equal error, nil
  end

  test "Error#eql? returns same result as ==" do
    error1 = Errors::Error.new(attribute: :name, message: "can't be blank")
    error2 = Errors::Error.new(attribute: :name, message: "can't be blank")
    error3 = Errors::Error.new(attribute: :email, message: "can't be blank")

    assert error1.eql?(error2)
    assert_not error1.eql?(error3)
  end

  test "Error#hash returns same value for equal errors" do
    error1 = Errors::Error.new(attribute: :name, message: "can't be blank")
    error2 = Errors::Error.new(attribute: :name, message: "can't be blank")

    assert_equal error1.hash, error2.hash
  end

  test "Error#hash allows errors to work in Set" do
    error1 = Errors::Error.new(attribute: :name, message: "can't be blank")
    error2 = Errors::Error.new(attribute: :name, message: "can't be blank")
    error3 = Errors::Error.new(attribute: :email, message: "is invalid")

    set = Set.new
    set.add(error1)
    set.add(error2) # Should not be added due to duplicate
    set.add(error3)

    assert_equal 2, set.size
  end

  # Errors tests

  test "#initialize creates empty errors container" do
    errors = Errors.new

    assert_predicate errors, :empty?
  end

  test "#add adds an error for an attribute" do
    errors = Errors.new
    errors.add(:name, message: "can't be blank")

    assert_not_predicate errors, :empty?
    assert_equal 1, errors[:name].size
  end

  test "#add converts attribute to symbol" do
    errors = Errors.new
    errors.add("name", message: "can't be blank")

    assert_equal 1, errors[:name].size
  end

  test "#add prevents duplicate errors for same attribute and message" do
    errors = Errors.new
    errors.add(:name, message: "can't be blank")
    errors.add(:name, message: "can't be blank")

    assert_equal 1, errors[:name].size
  end

  test "#add allows multiple different errors for same attribute" do
    errors = Errors.new
    errors.add(:name, message: "can't be blank")
    errors.add(:name, message: "is too short")

    assert_equal 2, errors[:name].size
  end

  test "#add allows errors for multiple attributes" do
    errors = Errors.new
    errors.add(:name, message: "can't be blank")
    errors.add(:email, message: "is invalid")

    assert_equal 1, errors[:name].size
    assert_equal 1, errors[:email].size
  end

  test "#added? returns true when error exists" do
    errors = Errors.new
    errors.add(:name, message: "can't be blank")

    assert errors.added?(:name, message: "can't be blank")
  end

  test "#added? returns false when error doesn't exist" do
    errors = Errors.new
    errors.add(:name, message: "can't be blank")

    assert_not errors.added?(:name, message: "is too short")
    assert_not errors.added?(:email, message: "can't be blank")
  end

  test "#added? returns false for empty errors" do
    errors = Errors.new

    assert_not errors.added?(:name, message: "can't be blank")
  end

  test "#added? converts attribute to symbol" do
    errors = Errors.new
    errors.add(:name, message: "can't be blank")

    assert errors.added?("name", message: "can't be blank")
  end

  test "#added? converts message to string" do
    errors = Errors.new
    errors.add(:count, message: "must be positive")

    assert errors.added?(:count, message: "must be positive")
  end

  test "#empty? returns true when no errors added" do
    errors = Errors.new

    assert_predicate errors, :empty?
  end

  test "#empty? returns false when errors exist" do
    errors = Errors.new
    errors.add(:name, message: "can't be blank")

    assert_not_predicate errors, :empty?
  end

  test "#full_messages returns array of full error messages" do
    errors = Errors.new
    errors.add(:first_name, message: "can't be blank")
    errors.add(:email, message: "is invalid")

    messages = errors.full_messages

    assert_equal 2, messages.size
    assert_includes messages, "First name can't be blank"
    assert_includes messages, "Email is invalid"
  end

  test "#full_messages returns empty array when no errors" do
    errors = Errors.new

    assert_equal [], errors.full_messages
  end

  test "#full_messages includes base errors without attribute" do
    errors = Errors.new
    errors.add(:base, message: "Something went wrong")
    errors.add(:name, message: "can't be blank")

    messages = errors.full_messages

    assert_equal 2, messages.size
    assert_includes messages, "Something went wrong"
    assert_includes messages, "Name can't be blank"
  end

  test "#[] returns array of Error objects for attribute" do
    errors = Errors.new
    errors.add(:name, message: "can't be blank")
    errors.add(:name, message: "is too short")

    name_errors = errors[:name]

    assert_equal 2, name_errors.size
    assert name_errors.all? { |error| error.is_a?(Errors::Error) }
    assert name_errors.any? { |error| error.message == "can't be blank" }
    assert name_errors.any? { |error| error.message == "is too short" }
  end

  test "#[] returns empty array for attribute with no errors" do
    errors = Errors.new
    errors.add(:name, message: "can't be blank")

    assert_equal [], errors[:email]
  end

  test "#[] converts attribute to symbol" do
    errors = Errors.new
    errors.add(:name, message: "can't be blank")

    assert_equal 1, errors["name"].size
  end
end
