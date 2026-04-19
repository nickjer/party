# frozen_string_literal: true

# Reusable length-bounds rule. Instantiate once per rule (typically as a
# named constant on the class that owns the field) and call `error_for`
# from forms or `validate!` from domain setters.
class LengthValidator
  # @dynamic min, max
  attr_reader :min, :max

  def initialize(min:, max:, field:)
    @min = min
    @max = max
    @field = field
  end

  def error_for(value)
    if value.length < min
      "is too short (minimum is #{min} characters)"
    elsif value.length > max
      "is too long (maximum is #{max} characters)"
    end
  end

  def validate!(value)
    return if value.length.between?(min, max)

    raise ArgumentError, "#{field.to_s.humanize} length must be " \
      "between #{min} and #{max} characters"
  end

  private

  # @dynamic field
  attr_reader :field
end
