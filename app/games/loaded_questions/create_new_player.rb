# frozen_string_literal: true

module LoadedQuestions
  # Builder object for creating new players joining a Loaded Questions game.
  class CreateNewPlayer
    def initialize(game_id:, user:, name:, guesser: false)
      @game_id = game_id
      @user = user
      @name = name
      @guesser = guesser
    end

    def call
      player = ::Player.new
      player.game_id = game_id
      player.user = user
      player.name = name
      player.document = document.to_json
      player.save!
      player
    end

    private

    # @dynamic game_id
    attr_reader :game_id

    # @dynamic guesser
    attr_reader :guesser

    # @dynamic name
    attr_reader :name

    # @dynamic user
    attr_reader :user

    def document
      {
        active: true,
        answer: "",
        guesser:,
        score: 0
      }
    end
  end
end
