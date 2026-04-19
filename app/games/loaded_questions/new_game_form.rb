# frozen_string_literal: true

module LoadedQuestions
  # Form object for validating new game creation with player name and question.
  class NewGameForm
    # @dynamic player_name
    attr_reader :player_name

    # @dynamic question
    attr_reader :question

    # @dynamic errors
    attr_reader :errors

    def initialize(player_name: nil, question: nil)
      @player_name = ::NormalizedString.new(player_name)
      question ||= Questions.instance.question
      @question = ::NormalizedString.new(question)
      @errors = Errors.new
    end

    def valid?
      if (error = ::PlayerName::LENGTH.error_for(player_name))
        errors.add(:player_name, message: error)
      end

      if (error = Game::QUESTION_LENGTH.error_for(question))
        errors.add(:question, message: error)
      end

      errors.empty?
    end
  end
end
