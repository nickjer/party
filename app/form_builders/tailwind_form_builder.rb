# frozen_string_literal: true

class TailwindFormBuilder < ActionView::Helpers::FormBuilder
  CHECK_BOX_STYLE = %w[
    w-4
    h-4
    text-blue-600
    bg-gray-100
    border-gray-300
    rounded-sm
  ].join(" ").freeze

  LABEL_STYLE = %w[
    text-sm
    font-medium
    text-gray-900
  ].join(" ").freeze

  SUBMIT_STYLE = %w[
    bg-blue-500
    text-white
    p-2
    text-sm
    rounded-lg
  ].join(" ").freeze

  TEXT_FIELD_STYLE = %w[
    bg-gray-50
    border
    border-gray-300
    text-gray-900
    text-sm
    rounded-lg
    p-2.5
  ].join(" ").freeze

  def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    options[:class] = "#{CHECK_BOX_STYLE} #{options[:class]}"
    super(method, options, checked_value, unchecked_value)
  end

  def label(method, text = nil, options = {}, &block)
    if text.is_a?(Hash)
      text[:class] = "#{LABEL_STYLE} #{text[:class]}"
    else
      options[:class] = "#{LABEL_STYLE} #{options[:class]}"
    end
    super(method, text, options, &block)
  end

  def text_field(method, options = {})
    options[:class] = "#{TEXT_FIELD_STYLE} #{options[:class]}"
    super(method, options)
  end

  def text_area(method, options = {})
    options[:class] = "border rounded #{options[:class]}"
    super(method, options)
  end

  def email_field(method, options = {})
    options[:class] = "border rounded #{options[:class]}"
    super(method, options)
  end

  def password_field(method, options = {})
    options[:class] = "border rounded #{options[:class]}"
    super(method, options)
  end

  def submit(value = "Submit", options = {})
    options[:class] = "#{SUBMIT_STYLE} #{options[:class]}"
    super(value, options)
  end
end
