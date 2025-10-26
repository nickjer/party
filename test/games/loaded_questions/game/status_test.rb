# frozen_string_literal: true

require "test_helper"

module LoadedQuestions
  class Game
    class StatusTest < ActiveSupport::TestCase
      test ".polling returns polling status" do
        status = Status.polling

        assert_predicate status, :polling?
        assert_not_predicate status, :guessing?
        assert_not_predicate status, :completed?
      end

      test ".guessing returns guessing status" do
        status = Status.guessing

        assert_predicate status, :guessing?
        assert_not_predicate status, :polling?
        assert_not_predicate status, :completed?
      end

      test ".completed returns completed status" do
        status = Status.completed

        assert_predicate status, :completed?
        assert_not_predicate status, :polling?
        assert_not_predicate status, :guessing?
      end

      test ".parse returns polling status for 'polling' string" do
        status = Status.parse("polling")

        assert_predicate status, :polling?
        assert_not_predicate status, :guessing?
        assert_not_predicate status, :completed?
      end

      test ".parse returns guessing status for 'guessing' string" do
        status = Status.parse("guessing")

        assert_predicate status, :guessing?
        assert_not_predicate status, :polling?
        assert_not_predicate status, :completed?
      end

      test ".parse returns completed status for 'completed' string" do
        status = Status.parse("completed")

        assert_predicate status, :completed?
        assert_not_predicate status, :polling?
        assert_not_predicate status, :guessing?
      end

      test ".parse raises ArgumentError for unknown status" do
        error = assert_raises(ArgumentError) do
          Status.parse("invalid_status")
        end

        assert_match(/Unknown status: invalid_status/, error.message)
      end

      test "#polling? returns true for polling status" do
        status = Status.polling

        assert_predicate status, :polling?
      end

      test "#polling? returns false for guessing status" do
        status = Status.guessing

        assert_not_predicate status, :polling?
      end

      test "#polling? returns false for completed status" do
        status = Status.completed

        assert_not_predicate status, :polling?
      end

      test "#guessing? returns true for guessing status" do
        status = Status.guessing

        assert_predicate status, :guessing?
      end

      test "#guessing? returns false for polling status" do
        status = Status.polling

        assert_not_predicate status, :guessing?
      end

      test "#guessing? returns false for completed status" do
        status = Status.completed

        assert_not_predicate status, :guessing?
      end

      test "#completed? returns true for completed status" do
        status = Status.completed

        assert_predicate status, :completed?
      end

      test "#completed? returns false for polling status" do
        status = Status.polling

        assert_not_predicate status, :completed?
      end

      test "#completed? returns false for guessing status" do
        status = Status.guessing

        assert_not_predicate status, :completed?
      end

      test "#== returns true for same status" do
        status1 = Status.polling
        status2 = Status.polling

        assert_equal status1, status2
      end

      test "#== returns false for different status" do
        status1 = Status.polling
        status2 = Status.guessing

        assert_not_equal status1, status2
      end

      test "#eql? returns true for same status" do
        status1 = Status.polling
        status2 = Status.polling

        assert status1.eql?(status2)
      end

      test "#eql? returns false for different status" do
        status1 = Status.polling
        status2 = Status.guessing

        assert_not status1.eql?(status2)
      end

      test "#hash returns same hash for same status" do
        status1 = Status.polling
        status2 = Status.polling

        assert_equal status1.hash, status2.hash
      end

      test "#hash returns different hash for different status" do
        status1 = Status.polling
        status2 = Status.guessing

        assert_not_equal status1.hash, status2.hash
      end

      test "#to_s returns string representation of polling status" do
        status = Status.polling

        assert_equal "polling", status.to_s
      end

      test "#to_s returns string representation of guessing status" do
        status = Status.guessing

        assert_equal "guessing", status.to_s
      end

      test "#to_s returns string representation of completed status" do
        status = Status.completed

        assert_equal "completed", status.to_s
      end

      test "#as_json returns string representation of polling status" do
        status = Status.polling

        assert_equal "polling", status.as_json
      end

      test "#as_json returns string representation of guessing status" do
        status = Status.guessing

        assert_equal "guessing", status.as_json
      end

      test "#as_json returns string representation of completed status" do
        status = Status.completed

        assert_equal "completed", status.as_json
      end

      test "status objects can be used as hash keys" do
        hash = {
          Status.polling => "polling_value",
          Status.guessing => "guessing_value",
          Status.completed => "completed_value"
        }

        assert_equal "polling_value", hash[Status.polling]
        assert_equal "guessing_value", hash[Status.guessing]
        assert_equal "completed_value", hash[Status.completed]
      end

      test ".new is private and cannot be called directly" do
        error = assert_raises(NoMethodError) do
          Status.new(:polling)
        end

        assert_match(/private method 'new' called/, error.message)
      end
    end
  end
end
