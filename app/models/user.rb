# frozen_string_literal: true

# Minimal user model for session-based tracking without authentication.
class User < ApplicationRecord
  validates :last_seen_at, presence: true
end
