# frozen_string_literal: true

# Abstract base class for all ActiveRecord models.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  class << self
    def generate_unique_id(length: 6)
      loop do
        random_id = SecureRandom.alphanumeric(length)
        return random_id unless exists?(id: random_id)
      end
    end
  end

  def initialize(attributes = {})
    super

    self.id ||= self.class.generate_unique_id
  end
end
