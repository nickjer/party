# frozen_string_literal: true

# Custom form builder that automatically applies Bootstrap CSS classes
# and inline error display.
class BootstrapFormBuilder < ActionView::Helpers::FormBuilder
  def check_box(method, options = {}, checked_value = "1",
    unchecked_value = "0")
    options[:class] = "form-check-input #{options[:class]}"
    super
  end

  def label(method, text = nil, options = {}, &)
    style = error?(method) ? "form-label text-danger" : "form-label"
    if text.is_a?(Hash)
      text[:class] = "#{style} #{text[:class]}"
    else
      options[:class] = "#{style} #{options[:class]}"
    end
    super
  end

  def text_field(method, options = {})
    style = error?(method) ? "form-control is-invalid" : "form-control"
    options[:class] = "#{style} #{options[:class]}"
    add_error(method, super)
  end

  def text_area(method, options = {})
    style = error?(method) ? "form-control is-invalid" : "form-control"
    options[:class] = "#{style} #{options[:class]}"
    add_error(method, super)
  end

  def select(method, choices = nil, options = {}, html_options = {}, &)
    style = error?(method) ? "form-select is-invalid" : "form-select"
    html_options[:class] = "#{style} #{html_options[:class]}"
    add_error(method, super)
  end

  def submit(value = "Submit", options = {})
    options[:class] = "btn btn-primary #{options[:class]}"
    super
  end

  private

  def error?(method)
    @object.errors[method].present?
  end

  def add_error(method, output)
    if error?(method)
      error_messages = @object.errors[method].join(". ")
      error = @template.content_tag(
        :div, error_messages, class: "invalid-feedback d-block"
      )
      output.concat(error)
    end
    output
  end
end
