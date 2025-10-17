# frozen_string_literal: true

# Core game model with document-oriented architecture. All game-specific state is stored in the JSON document field, enabling multiple game types without schema changes.
class Game < ApplicationRecord
  MIN_QUESTION_LENGTH = 3
  MAX_QUESTION_LENGTH = 160

  attribute :document, :string

  enum :kind, {
    loaded_questions: 0
  }

  validates :slug, uniqueness: true

  has_many :players, dependent: :destroy

  def broadcast_reload_game
    ::Turbo::StreamsChannel
      .broadcast_action_to(self, action: :reload, target: "game")
  end

  def broadcast_reload_players
    ::Turbo::StreamsChannel
      .broadcast_action_to(self, action: :reload, target: "players")
  end

  def document=(raw_json)
    @parsed_document = nil
    super
  end

  def kind = super.to_sym

  def parsed_document
    @parsed_document ||= JSON.parse(document, symbolize_names: true)
  end
end
