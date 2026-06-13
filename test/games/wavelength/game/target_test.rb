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

        assert_equal 4, target.score_for(50) # distance 0
        assert_equal 4, target.score_for(48) # distance 2
        assert_equal 4, target.score_for(52)
      end

      test "#score_for awards 3 in the inner band" do
        target = Target.new(position: 50)

        assert_equal 3, target.score_for(45) # distance 5
        assert_equal 3, target.score_for(55)
      end

      test "#score_for awards 2 in the outer band" do
        target = Target.new(position: 50)

        assert_equal 2, target.score_for(40) # distance 10
        assert_equal 2, target.score_for(60)
      end

      test "#score_for awards 0 outside the bands" do
        target = Target.new(position: 50)

        assert_equal 0, target.score_for(35) # distance 15
        assert_equal 0, target.score_for(65)
      end

      test "#score_for steps down at the bullseye/inner edge" do
        target = Target.new(position: 50)

        assert_equal 4, target.score_for(48) # distance 2
        assert_equal 4, target.score_for(52)
        assert_equal 3, target.score_for(47) # distance 3
        assert_equal 3, target.score_for(53)
      end

      test "#score_for steps down at the inner/outer edge" do
        target = Target.new(position: 50)

        assert_equal 3, target.score_for(43) # distance 7
        assert_equal 3, target.score_for(57)
        assert_equal 2, target.score_for(42) # distance 8
        assert_equal 2, target.score_for(58)
      end

      test "#score_for steps down at the outer/miss edge" do
        target = Target.new(position: 50)

        assert_equal 2, target.score_for(38) # distance 12
        assert_equal 2, target.score_for(62)
        assert_equal 0, target.score_for(37) # distance 13
        assert_equal 0, target.score_for(63)
      end

      test "#score_for handles dials at the dial extremes" do
        assert_equal 4, Target.new(position: 0).score_for(0)
        assert_equal 0, Target.new(position: 0).score_for(100)
        assert_equal 4, Target.new(position: 100).score_for(100)
      end

      test "#side_of reports which side the target is on" do
        target = Target.new(position: 60)

        assert_equal :right, target.side_of(50)
        assert_equal :left, target.side_of(70)
        assert_equal :exact, target.side_of(60)
      end

      test "#bands maps the five equal scoring wedges onto the track" do
        bands = Target.new(position: 50).bands

        assert_equal [2, 3, 4, 3, 2], bands.map(&:points)
        assert_equal [37.5, 42.5, 47.5, 52.5, 57.5], bands.map(&:from)
        assert_equal [42.5, 47.5, 52.5, 57.5, 62.5], bands.map(&:to)
        assert_equal [5.0, 5.0, 5.0, 5.0, 5.0], bands.map(&:width)
      end

      test "#bands clamps wedges to the dial edges" do
        bands = Target.new(position: 2).bands

        assert_equal [0.0, 0.0], bands.first(2).map(&:width)
        assert_equal 0.0, bands[2].from
        assert_equal 4.5, bands[2].to
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
