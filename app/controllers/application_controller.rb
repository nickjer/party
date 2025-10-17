# frozen_string_literal: true

# Base controller that handles session-based user authentication and modern browser requirements.
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :require_user

  private

  # @return [::User]
  attr_reader :current_user

  # @return [void]
  def require_user
    @current_user = User.find_by(id: current_user_id) || User.new
    @current_user.update!(last_seen_at: Time.current)
    self.current_user_id = @current_user.id
  end

  # @return [Integer, nil]
  def current_user_id = cookies.encrypted[:current_user_id].presence

  # @param user_id [Integer]
  # @return [void]
  def current_user_id=(user_id)
    cookies.permanent.encrypted[:current_user_id] = user_id
  end
end
