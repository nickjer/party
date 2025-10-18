# frozen_string_literal: true

module LoadedQuestions
  # Builder object for starting a new round in an existing game
  class CreateNewRound
    def initialize(game:, guesser:, question:)
      @game = game
      @guesser = guesser
      @question = question
    end

    def call
      game_model = game.to_model
      game_model.document = game_document.to_json

      # Update all player documents
      game_model.players.each do |player_model|
        player_model.document = player_document(player_model).to_json
      end

      # Save all changes in a transaction
      ::ActiveRecord::Base.transaction do
        game_model.save!
        game_model.players.each(&:save!)
      end

      game
    end

    private

    # @dynamic game, guesser, question
    attr_reader :game, :guesser, :question

    def game_document
      {
        guesses: Game::Guesses.new(guesses: []),
        question: question,
        status: Game::Status.polling
      }
    end

    def player_document(player_model)
      {
        active: true,
        answer: "",
        guesser: (player_model.id == guesser.id)
      }
    end
  end
end
