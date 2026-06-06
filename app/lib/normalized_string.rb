# frozen_string_literal: true

# Immutable value object for normalized text with case-insensitive comparison
# using NFKC Unicode normalization.
class NormalizedString
  # Cyrillic/Greek letters that look like Latin ones, folded into the comparison
  # key so look-alikes count as equal. The displayed string is left untouched.
  CONFUSABLES = {
    "а" => "a", "в" => "b", "е" => "e", "ё" => "e", "к" => "k", "м" => "m",
    "н" => "h", "о" => "o", "р" => "p", "с" => "c", "т" => "t", "у" => "y",
    "х" => "x", "і" => "i", "ј" => "j", "ѕ" => "s",
    "α" => "a", "β" => "b", "ε" => "e", "η" => "n", "ι" => "i", "κ" => "k",
    "μ" => "u", "ν" => "v", "ο" => "o", "ρ" => "p", "τ" => "t", "υ" => "y",
    "χ" => "x", "γ" => "y", "ω" => "w"
  }.freeze

  CONFUSABLE_PATTERN = Regexp.union(CONFUSABLES.keys)

  def initialize(string) = @string = normalize(string)

  def <=>(other) = sortable_value <=> other.sortable_value

  def ==(other) = sortable_value == other.sortable_value

  def as_json = string

  def blank? = string.blank?

  def eql?(other) = self == other

  def hash = sortable_value.hash

  def length = string.length

  def to_s = string

  protected

  def sortable_value
    string.downcase
      .gsub(CONFUSABLE_PATTERN, CONFUSABLES)
      .gsub(/[^\p{Word}]/, "")
  end

  private

  # @dynamic string
  attr_reader :string

  def normalize(value)
    value.to_s.unicode_normalize(:nfkc).squish.gsub(/\P{Print}|\p{Cf}/, "")
  end
end
