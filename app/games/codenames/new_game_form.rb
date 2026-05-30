# frozen_string_literal: true

module Codenames
  # Form object for validating new game creation with the creator's name.
  class NewGameForm
    # @dynamic player_name_input
    attr_reader :player_name_input

    # @dynamic player_name
    attr_reader :player_name

    # @dynamic errors
    attr_reader :errors

    def initialize(player_name: nil)
      @player_name_input = ::NormalizedString.new(player_name)
      @errors = Errors.new
    end

    def valid?
      @player_name = ::PlayerName.build(player_name_input, errors:,
        attribute: :player_name)
      errors.empty?
    end
  end
end
