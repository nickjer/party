class Game < ApplicationRecord
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
end
