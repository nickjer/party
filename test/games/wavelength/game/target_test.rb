# frozen_string_literal: true

require "test_helper"

module Wavelength
  class Game
    class TargetTest < ActiveSupport::TestCase
      test ".generate produces a position anywhere on the dial" do
        100.times do
          assert_includes 0..100, Target.generate.position
        end
      end

      test "#score_for awards 4 within the bullseye band" do
        target = Target.new(position: 50)

        assert_equal 4, target.score_for(50)
        assert_equal 4, target.score_for(47)
        assert_equal 4, target.score_for(53)
      end

      test "#score_for awards 3 in the inner band" do
        target = Target.new(position: 50)

        assert_equal 3, target.score_for(46)
        assert_equal 3, target.score_for(55)
      end

      test "#score_for awards 2 in the outer band" do
        target = Target.new(position: 50)

        assert_equal 2, target.score_for(43)
        assert_equal 2, target.score_for(58)
      end

      test "#score_for awards 0 outside the bands" do
        target = Target.new(position: 50)

        assert_equal 0, target.score_for(40)
        assert_equal 0, target.score_for(61)
      end

      test "#side_of reports which side the target is on" do
        target = Target.new(position: 60)

        assert_equal :right, target.side_of(50)
        assert_equal :left, target.side_of(70)
        assert_equal :exact, target.side_of(60)
      end

      test "#== compares by position" do
        assert_equal Target.new(position: 42), Target.new(position: 42)
        assert_not_equal Target.new(position: 42), Target.new(position: 43)
      end

      test "#== is false for non-target values" do
        assert_not_equal Target.new(position: 42), 42
      end

      test "#eql? and #hash allow targets as hash keys" do
        counts = { Target.new(position: 42) => 1 }

        assert_equal 1, counts[Target.new(position: 42)]
      end
    end
  end
end
