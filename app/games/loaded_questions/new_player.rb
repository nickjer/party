# frozen_string_literal: true

module LoadedQuestions
  # Builder object for constructing new players joining a Loaded Questions game.
  class NewPlayer
    class << self
      def from(new_player_form, guesser: false)
        new(
          user: new_player_form.user,
          name: new_player_form.name,
          guesser:
        )
      end
    end

    def initialize(user:, name:, guesser:)
      @user = user
      @name = name
      @guesser = guesser
    end

    def build
      player = ::Player.new
      player.user = user
      player.name = name
      player.document = document.to_json
      player
    end

    private

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
        guesser:
      }
    end
  end
end
