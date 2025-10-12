class Player < ApplicationRecord
  MIN_NAME_LENGTH = 3
  MAX_NAME_LENGTH = 25

  belongs_to :game
  belongs_to :user

  validates :user_id, uniqueness: { scope: :game_id }
  validate :name_uniqueness_within_game

  attribute :document, :string

  def document=(raw_json)
    @parsed_document = nil
    super(raw_json)
  end

  def name = NormalizedString.new(super)

  def online? = PlayerConnections.instance.count(id).positive?

  def parsed_document
    @parsed_document ||= JSON.parse(document, symbolize_names: true)
  end

  private

  def name_uniqueness_within_game
    return unless will_save_change_to_name?

    existing_names = Player.where(game_id:).where.not(id:).pluck(:name)

    if existing_names.any? { |existing| NormalizedString.new(existing) == name }
      errors.add(:name, :taken, value: self[:name])
    end
  end
end
