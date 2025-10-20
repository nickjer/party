# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class QuestionsTest < ActiveSupport::TestCase
    test ".instance returns singleton instance" do
      instance1 = Questions.instance
      instance2 = Questions.instance

      assert_same instance1, instance2
    end

    test "#question returns a string" do
      question = Questions.instance.question

      assert_instance_of String, question
    end

    test "#question returns a non-empty string" do
      question = Questions.instance.question

      assert_not question.empty?
    end

    test "#question returns different questions on multiple calls" do
      questions = 10.times.map { Questions.instance.question }

      assert questions.uniq.length > 1, "Expected multiple unique questions"
    end

    test "#question returns questions from the YAML file" do
      question = Questions.instance.question

      expected_questions = YAML.load_file(
        Rails.root.join("config/loaded_questions/questions.yml")
      ).fetch("shared")

      assert_includes expected_questions, question
    end
  end
end
