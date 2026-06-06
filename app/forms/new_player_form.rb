# frozen_string_literal: true

# Validates new player creation. Game-agnostic; shared across all game kinds.
class NewPlayerForm
  # @dynamic game
  attr_reader :game

  # @dynamic name
  attr_reader :name

  # @dynamic player_name
  attr_reader :player_name

  # @dynamic errors
  attr_reader :errors

  # @dynamic user_id
  attr_reader :user_id

  def initialize(game:, user_id:, name: nil)
    @game = game
    @user_id = user_id
    @name = NameEasterEgg.new(name).apply
    @errors = Errors.new
  end

  def valid?
    @player_name = ::PlayerName.build(name, errors:)
    if player_name
      ::PlayerNameValidator.new(game:, name: player_name).apply_to(errors)
    end
    ::UniquePlayerValidator.new(game:, user_id:).apply_to(errors)
    errors.empty?
  end
end
