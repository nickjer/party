# frozen_string_literal: true

class BootstrapFormBuilder < ActionView::Helpers::FormBuilder
  def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    options[:class] = "form-check-input #{options[:class]}"
    super(method, options, checked_value, unchecked_value)
  end

  def label(method, text = nil, options = {}, &block)
    style = error?(method) ? "form-label text-danger" : "form-label"
    if text.is_a?(Hash)
      text[:class] = "#{style} #{text[:class]}"
    else
      options[:class] = "#{style} #{options[:class]}"
    end
    super(method, text, options, &block)
  end

  def text_field(method, options = {})
    style = error?(method) ? "form-control is-invalid" : "form-control"
    options[:class] = "#{style} #{options[:class]}"
    output = super(method, options)
    if error?(method)
      error = @template.content_tag(
        :div, @object.errors[method].join(", "), class: "invalid-feedback d-block"
      )
      output.concat(error)
    end
    output
  end

  def text_area(method, options = {})
    style = error?(method) ? "form-control is-invalid" : "form-control"
    options[:class] = "#{style} #{options[:class]}"
    output = super(method, options)
    if error?(method)
      error = @template.content_tag(
        :div, @object.errors[method].join(", "), class: "invalid-feedback d-block"
      )
      output.concat(error)
    end
    output
  end

  def email_field(method, options = {})
    style = error?(method) ? "form-control is-invalid" : "form-control"
    options[:class] = "#{style} #{options[:class]}"
    super(method, options)
  end

  def password_field(method, options = {})
    style = error?(method) ? "form-control is-invalid" : "form-control"
    options[:class] = "#{style} #{options[:class]}"
    super(method, options)
  end

  def submit(value = "Submit", options = {})
    options[:class] = "btn btn-primary #{options[:class]}"
    super(value, options)
  end

  private

  def error?(method)
    @object.errors[method].present?
  end
end
