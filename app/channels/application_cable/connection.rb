# frozen_string_literal: true

module ApplicationCable
  # WebSocket connection handler that authenticates users via encrypted
  # session cookies.
  class Connection < ActionCable::Connection::Base
    # @dynamic current_user, current_user=
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      if (verified_user = User.find_by(id: cookies.encrypted[:current_user_id]))
        verified_user
      else
        reject_unauthorized_connection
      end
    end
  end
end
