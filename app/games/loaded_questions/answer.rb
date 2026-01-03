# frozen_string_literal: true

module LoadedQuestions
  # Value object representing a player's answer with a random id for
  # frontend identification without revealing who wrote it.
  class Answer
    # @dynamic id, value
    attr_reader :id, :value

    class << self
      def build(value:) = new(id: SecureRandom.uuid, value:)

      def empty = build(value: "")

      def parse(data) = new(id: data.fetch(:id), value: data.fetch(:value))
    end

    def initialize(id:, value:)
      @id = id
      @value = NormalizedString.new(value)
    end

    def <=>(other) = value <=> other.value

    def ==(other) = value == other.value

    def blank? = value.blank?

    def to_s = value.to_s

    def as_json
      { id:, value: }.as_json
    end
  end
end
