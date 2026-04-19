# frozen_string_literal: true

# Length-validated name newtype. Compare only PlayerName to PlayerName.
class PlayerName
  LENGTH = LengthValidator.new(min: 3, max: 25, field: :name)

  class << self
    def parse(raw) = new(NormalizedString.new(raw))
  end

  def initialize(normalized)
    LENGTH.validate!(normalized)
    @normalized = normalized
  end

  def <=>(other) = normalized <=> other.normalized

  def ==(other) = normalized == other.normalized

  def eql?(other) = self == other

  def hash = normalized.hash

  def to_s = normalized.to_s

  protected

  # @dynamic normalized
  attr_reader :normalized
end
