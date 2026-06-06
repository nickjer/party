# frozen_string_literal: true

# Easter egg: "Bethany" becomes "Betsy" wherever it appears, even when disguised
# with leetspeak, look-alike glyphs, repeats, or separators between the letters.
class NameEasterEgg
  # Look-alikes for each letter of "bethany", in order; matched ignoring case.
  LOOKALIKES = {
    "b" => %w[b 8 6],
    "e" => %w[e 3 € е ё],
    "t" => %w[t 7],
    "h" => %w[h н],
    "a" => %w[a 4 @ а],
    "n" => %w[n η],
    "y" => %w[y у ý]
  }.freeze

  # Junk a user might wedge between letters. Disjoint from the look-alikes above
  # so the matcher stays linear (no catastrophic backtracking).
  SEPARATOR = '[\s._-]*'

  TRIGGER = begin
    classes = LOOKALIKES.values.map { |glyphs| "[#{glyphs.join}]+" }
    /(?<![\p{L}\p{N}])#{classes.join(SEPARATOR)}(?![\p{L}\p{N}])/i
  end

  def initialize(raw)
    @name = NormalizedString.new(raw)
  end

  def apply
    rewritten = name.to_s.gsub(TRIGGER) { |match| replacement_for(match) }
    NormalizedString.new(rewritten)
  end

  private

  # @dynamic name
  attr_reader :name

  def replacement_for(match)
    return "betsy" if match == match.downcase
    return "BETSY" if match == match.upcase

    "Betsy"
  end
end
