class User < ApplicationRecord
  validates :last_seen_at, presence: true
end
