# frozen_string_literal: true

module Codenames
  # Form object for validating the spymaster's clue: a word plus a number
  # (0-9 or unlimited).
  class ClueForm
    NUMBERS = [*"0".."9", "unlimited"].freeze

    # @dynamic word
    attr_reader :word

    # @dynamic number
    attr_reader :number

    # @dynamic errors
    attr_reader :errors

    def initialize(word: nil, number: nil)
      @word = ::NormalizedString.new(word)
      @number = number&.to_s
      @errors = Errors.new
    end

    def valid?
      if (error = Game::CLUE_LENGTH.error_for(word))
        errors.add(:word, message: error)
      end
      unless NUMBERS.include?(number)
        errors.add(:number, message: "must be 0-9 or unlimited")
      end

      errors.empty?
    end

    # Only meaningful after #valid?; nil means unlimited.
    def parsed_number
      raw = number
      raw.nil? || raw == "unlimited" ? nil : Integer(raw)
    end
  end
end
