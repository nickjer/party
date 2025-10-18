# frozen_string_literal: true

# A lightweight errors container similar to ActiveModel::Errors
class Errors
  # Represents a single error for an attribute
  class Error
    # @dynamic attribute, message
    attr_reader :attribute, :message

    def initialize(attribute:, message:)
      @attribute = attribute.to_sym
      @message = message.to_s
    end

    def full_message
      if attribute == :base
        message
      else
        "#{ActiveSupport::Inflector.humanize(attribute)} #{message}"
      end
    end

    def to_s = full_message

    def ==(other)
      other.is_a?(Error) &&
        other.attribute == attribute &&
        other.message == message
    end

    def eql?(other) = self == other

    def hash
      [attribute, message].hash
    end
  end

  def initialize
    @errors = {}
  end

  def add(attribute, message:)
    key = attribute.to_sym
    error_set = errors[key] || Set.new
    error_set.add(Error.new(attribute:, message:))
    errors[key] = error_set
  end

  def added?(attribute, message:)
    error_set = errors[attribute.to_sym]
    return false unless error_set

    error_set.any? { |error| error.message == message.to_s }
  end

  def empty?
    errors.empty? || errors.values.all?(&:empty?)
  end

  def [](attribute)
    error_set = errors[attribute.to_sym]
    return [] unless error_set

    error_set.to_a
  end

  private

  # @dynamic errors
  attr_reader :errors
end
