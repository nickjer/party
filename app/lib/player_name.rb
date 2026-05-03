# frozen_string_literal: true

# Length-validated name newtype. Compare only PlayerName to PlayerName.
class PlayerName
  LENGTH = LengthValidator.new(min: 3, max: 25, field: :name)

  class << self
    def parse(raw) = new(NormalizedString.new(raw))

    # Returns a PlayerName, or adds a length error to `errors` and returns nil.
    def build(normalized, errors:, attribute: :name)
      if (error = LENGTH.error_for(normalized))
        errors.add(attribute, message: error)
        nil
      else
        new(normalized)
      end
    end
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
