# frozen_string_literal: true

class User < ApplicationRecord
  validates :last_seen_at, presence: true
end
