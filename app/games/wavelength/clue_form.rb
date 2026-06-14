# frozen_string_literal: true

module Wavelength
  # Form object for validating the psychic's clue during the clue phase.
  class ClueForm
    # @dynamic text
    attr_reader :text

    # @dynamic errors
    attr_reader :errors

    def initialize(text: nil)
      @text = ::NormalizedString.new(text)
      @errors = Errors.new
    end

    def valid?
      if (error = Game::CLUE_LENGTH.error_for(text))
        errors.add(:text, message: error)
      end

      errors.empty?
    end
  end
end
