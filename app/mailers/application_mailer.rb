# frozen_string_literal: true

# Base mailer class that provides default configuration for all mailers.
class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"
end
