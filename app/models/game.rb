# frozen_string_literal: true

# Core game model with document-oriented architecture. All game-specific state
# is stored in the JSON document field, enabling multiple game types without
# schema changes.
class Game < ApplicationRecord
  attribute :document, :string

  enum :kind, {
    loaded_questions: 0,
    burn_unit: 1
  }

  has_many :players, dependent: :destroy

  def document=(raw_json)
    @parsed_document = nil
    super
  end

  def kind = super.to_sym

  def parsed_document
    @parsed_document ||= JSON.parse(document, symbolize_names: true)
  end
end
