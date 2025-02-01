class Game < ApplicationRecord
  has_many :players

  attribute :document, :string

  def document=(raw_json)
    @parsed_document = nil
    super(raw_json)
  end

  def parsed_document
    @parsed_document ||= JSON.parse(document, symbolize_names: true)
  end
end
