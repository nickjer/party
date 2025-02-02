class Player < ApplicationRecord
  MIN_NAME_LENGTH = 3
  MAX_NAME_LENGTH = 25

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
