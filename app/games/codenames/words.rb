# frozen_string_literal: true

module Codenames
  # Singleton that provides access to the pre-loaded word pool from YAML.
  class Words
    # @dynamic self.instance
    include Singleton

    def initialize
      @words = load_words
    end

    def sample(count = Game::Board::SIZE)
      raise "Not enough words loaded" if words.size < count

      words.sample(count)
    end

    private

    # @dynamic words
    attr_reader :words

    def load_words
      file_path = Rails.root.join("config/codenames/words.yml")
      yaml_content = YAML.load_file(file_path)
      empty = [] #: Array[String]
      yaml_content.fetch("shared", empty)
    end
  end
end
