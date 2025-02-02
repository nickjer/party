# frozen_string_literal: true

module LoadedQuestions
  class NewGameForm
    # @dynamic player_name
    attr_reader :player_name

    # @dynamic question
    attr_reader :question

    # @dynamic hide_answers
    attr_reader :hide_answers

    # @dynamic errors
    attr_reader :errors

    def initialize(params = nil)
      if params
        @player_name = params[:player_name].to_s
        @question = params[:question].to_s
        @hide_answers = params[:hide_answers] == "1"
      else
        @player_name = ""
        @question = ""
        @hide_answers = false
      end

      @errors = {}
    end

    def valid?
      min = ::Player::MIN_NAME_LENGTH
      max = ::Player::MAX_NAME_LENGTH
      if (error = validate_length(player_name, min:, max:))
        errors[:player_name] = error
      end

      min = ::Game::MIN_QUESTION_LENGTH
      max = ::Game::MAX_QUESTION_LENGTH
      if (error = validate_length(question, min:, max:))
        errors[:question] = error
      end

      errors.empty?
    end

    private

    def validate_length(value, min:, max:)
      if value.length < min
        "is too short (minimum is #{min} characters)"
      elsif value.length > max
        "is too long (maximum is #{max} characters)"
      end
    end
  end
end
