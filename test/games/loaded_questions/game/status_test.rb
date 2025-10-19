# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class Game
    class StatusTest < ActiveSupport::TestCase
      test ".parse raises ArgumentError for unknown status" do
        error = assert_raises(ArgumentError) do
          Status.parse("invalid_status")
        end

        assert_match(/Unknown status: invalid_status/, error.message)
      end
    end
  end
end
