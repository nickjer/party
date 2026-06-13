# frozen_string_literal: true

require "test_helper"

module Wavelength
  class SpectrumsTest < ActiveSupport::TestCase
    test "#sample returns a spectrum from the pool" do
      spectrum = Spectrums.instance.sample

      assert_instance_of Game::Spectrum, spectrum
      assert_kind_of String, spectrum.left
      assert_kind_of String, spectrum.right
    end

    test "#sample raises when the pool is empty" do
      Spectrums.instance.stubs(:cards).returns([])

      error = assert_raises(RuntimeError) { Spectrums.instance.sample }

      assert_match(/No spectrum cards loaded/, error.message)
    end
  end
end
