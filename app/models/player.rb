class Player < ApplicationRecord
  belongs_to :game
  belongs_to :user

  attribute :document, :string

  def document=(raw_json)
    @parsed_document = nil
    super(raw_json)
  end

  def name = NormalizedString.new(super)

  def parsed_document
    @parsed_document ||= JSON.parse(document, symbolize_names: true)
  end
end
