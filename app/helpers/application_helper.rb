# frozen_string_literal: true

# Application-wide view helpers that configure the default form builder.
module ApplicationHelper
  ActionView::Base.default_form_builder = BootstrapFormBuilder
end
