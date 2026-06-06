# frozen_string_literal: true

module LoadedQuestions
  # Form object for validating new game creation with player name and question.
  class NewGameForm
    # @dynamic player_name_input
    attr_reader :player_name_input

    # @dynamic player_name
    attr_reader :player_name

    # @dynamic question
    attr_reader :question

    # @dynamic errors
    attr_reader :errors

    def initialize(player_name: nil, question: nil)
      @player_name_input = ::NameEasterEgg.new(player_name).apply
      question ||= Questions.instance.question
      @question = ::NormalizedString.new(question)
      @errors = Errors.new
    end

    def valid?
      @player_name = ::PlayerName.build(player_name_input, errors:,
        attribute: :player_name)

      if (error = Game::QUESTION_LENGTH.error_for(question))
        errors.add(:question, message: error)
      end

      errors.empty?
    end
  end
end
