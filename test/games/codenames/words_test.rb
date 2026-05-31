# frozen_string_literal: true

require "test_helper"

module Codenames
  class WordsTest < ActiveSupport::TestCase
    test "#sample returns 25 distinct words by default" do
      words = Words.instance.sample

      assert_equal 25, words.size
      assert_equal 25, words.uniq.size
    end

    test "#sample accepts a custom count" do
      assert_equal 10, Words.instance.sample(10).size
    end

    test "#sample returns words from the pool" do
      assert(Words.instance.sample.all?(String))
    end

    test "#sample raises when the pool is smaller than the requested count" do
      error = assert_raises(ArgumentError) do
        Words.instance.sample(1_000_000)
      end

      assert_match(/requested 1000000 words/, error.message)
    end
  end
end
