# frozen_string_literal: true

class NormalizedString
  def initialize(string) = @string = normalize(string)

  def <=>(other) = sortable_value <=> other.sortable_value

  def ==(other) = sortable_value == other.sortable_value

  def blank? = string.blank?

  def eql?(other) = self == other

  def hash = sortable_value.hash

  def length = string.length

  def to_s = string

  protected

  def sortable_value = string.gsub(/[^\p{Word}]/, "").downcase

  private

  # @dynamic string
  attr_reader :string

  def normalize(value)
    value.to_s.unicode_normalize(:nfkc).squish.gsub(/\P{Print}|\p{Cf}/, "")
  end
end
