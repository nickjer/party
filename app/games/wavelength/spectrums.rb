# frozen_string_literal: true

module Wavelength
  # Singleton providing the pre-loaded spectrum-card pool from YAML.
  class Spectrums
    # @dynamic self.instance
    include Singleton

    def initialize
      @cards = load_cards
    end

    def sample = cards.sample || raise("No spectrum cards loaded")

    private

    # @dynamic cards
    attr_reader :cards

    def load_cards
      file_path = Rails.root.join("config/wavelength/spectrums.yml")
      yaml_content = YAML.safe_load_file(file_path)
      empty = [] #: Array[Hash[String, String]]
      rows = yaml_content.fetch("shared", empty)
      rows.map { |row| Game::Spectrum.parse(row.symbolize_keys) }
    end
  end
end
