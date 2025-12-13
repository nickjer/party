# frozen_string_literal: true

module BurnUnit
  # Singleton that provides access to pre-loaded questions from YAML
  class Questions
    # @dynamic self.instance
    include Singleton

    def initialize
      @questions = load_questions
    end

    def question
      questions.sample || raise("No questions loaded")
    end

    private

    # @dynamic questions
    attr_reader :questions

    def load_questions
      file_path = Rails.root.join("config/burn_unit/questions.yml")
      yaml_content = YAML.load_file(file_path)
      empty = [] #: Array[String]
      yaml_content.fetch("shared", empty)
    end
  end
end
