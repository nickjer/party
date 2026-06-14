# frozen_string_literal: true

require "test_helper"

module Wavelength
  class Game
    class SpectrumTest < ActiveSupport::TestCase
      test ".parse builds a spectrum from a hash" do
        spectrum = Spectrum.parse(left: "Cold", right: "Hot")

        assert_equal "Cold", spectrum.left
        assert_equal "Hot", spectrum.right
      end

      test "#== compares by both labels" do
        spectrum = Spectrum.new(left: "Cold", right: "Hot")

        assert_equal Spectrum.new(left: "Cold", right: "Hot"), spectrum
        assert_not_equal Spectrum.new(left: "Cool", right: "Hot"), spectrum
        assert_not_equal Spectrum.new(left: "Cold", right: "Warm"), spectrum
      end

      test "#== is false for non-spectrum values" do
        assert_not_equal Spectrum.new(left: "Cold", right: "Hot"), "Cold"
      end

      test "#eql? and #hash allow spectrums as hash keys" do
        counts = { Spectrum.new(left: "Cold", right: "Hot") => 1 }

        assert_equal 1, counts[Spectrum.new(left: "Cold", right: "Hot")]
      end

      test "#to_h returns the two labels" do
        spectrum = Spectrum.new(left: "Cold", right: "Hot")

        assert_equal({ left: "Cold", right: "Hot" }, spectrum.to_h)
      end
    end
  end
end
