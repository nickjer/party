class Game < ApplicationRecord
  MIN_QUESTION_LENGTH = 3
  MAX_QUESTION_LENGTH = 160

  attribute :document, :string

  enum :kind, {
    loaded_questions: 0
  }

  has_many :players

  def document=(raw_json)
    @parsed_document = nil
    super(raw_json)
  end

  def kind = super.to_sym

  def parsed_document
    @parsed_document ||= JSON.parse(document, symbolize_names: true)
  end

  def broadcast_reload_players
    ::Turbo::StreamsChannel
      .broadcast_action_to(self, action: :reload, target: "players")
  end
end
