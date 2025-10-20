# frozen_string_literal: true

require "test_helper"

class NormalizedStringTest < ActiveSupport::TestCase
  # Initialization and normalization

  test "#initialize normalizes string with NFKC" do
    # Using composed vs decomposed Unicode characters
    composed = NormalizedString.new("café")
    # e with combining acute accent
    decomposed = NormalizedString.new("cafe\u0301")

    assert_equal composed.to_s, decomposed.to_s
  end

  test "#initialize squishes whitespace" do
    string = NormalizedString.new("  hello   world  ")

    assert_equal "hello world", string.to_s
  end

  test "#initialize removes leading and trailing whitespace" do
    string = NormalizedString.new("  hello  ")

    assert_equal "hello", string.to_s
  end

  test "#initialize removes non-printable characters" do
    string = NormalizedString.new("hello\u0000world") # null character

    assert_equal "helloworld", string.to_s
  end

  test "#initialize removes format control characters" do
    string = NormalizedString.new("hello\u200Bworld") # zero-width space

    assert_equal "helloworld", string.to_s
  end

  test "#initialize converts non-string values to string" do
    string = NormalizedString.new(123)

    assert_equal "123", string.to_s
  end

  test "#initialize handles empty string" do
    string = NormalizedString.new("")

    assert_equal "", string.to_s
  end

  test "#initialize handles nil" do
    string = NormalizedString.new(nil)

    assert_equal "", string.to_s
  end

  # Equality and comparison

  test "#== returns true for identical strings" do
    string1 = NormalizedString.new("hello")
    string2 = NormalizedString.new("hello")

    assert_equal string1, string2
  end

  test "#== is case-insensitive" do
    string1 = NormalizedString.new("Hello")
    string2 = NormalizedString.new("hello")

    assert_equal string1, string2
  end

  test "#== is case-insensitive with mixed case" do
    string1 = NormalizedString.new("Hello World")
    string2 = NormalizedString.new("HELLO WORLD")

    assert_equal string1, string2
  end

  test "#== ignores non-word characters in comparison" do
    string1 = NormalizedString.new("hello-world")
    string2 = NormalizedString.new("hello world")

    assert_equal string1, string2
  end

  test "#== ignores punctuation in comparison" do
    string1 = NormalizedString.new("hello!")
    string2 = NormalizedString.new("hello")

    assert_equal string1, string2
  end

  test "#== returns false for different strings" do
    string1 = NormalizedString.new("hello")
    string2 = NormalizedString.new("world")

    assert_not_equal string1, string2
  end

  test "#== ignores whitespace differences in comparison" do
    string1 = NormalizedString.new("hello world")
    string2 = NormalizedString.new("helloworld")

    assert_equal string1, string2
  end

  test "#<=> compares strings case-insensitively" do
    string1 = NormalizedString.new("apple")
    string2 = NormalizedString.new("BANANA")

    assert_equal(-1, string1 <=> string2)
    assert_equal 1, string2 <=> string1
  end

  test "#<=> returns 0 for equal strings" do
    string1 = NormalizedString.new("hello")
    string2 = NormalizedString.new("HELLO")

    assert_equal 0, string1 <=> string2
  end

  test "#<=> ignores non-word characters" do
    string1 = NormalizedString.new("a-b-c")
    string2 = NormalizedString.new("abc")

    assert_equal 0, string1 <=> string2
  end

  test "#<=> allows sorting" do
    strings = [
      NormalizedString.new("Charlie"),
      NormalizedString.new("alice"),
      NormalizedString.new("BOB")
    ].sort

    assert_equal "alice", strings[0].to_s
    assert_equal "BOB", strings[1].to_s
    assert_equal "Charlie", strings[2].to_s
  end

  test "#eql? returns same result as ==" do
    string1 = NormalizedString.new("Hello")
    string2 = NormalizedString.new("hello")
    string3 = NormalizedString.new("world")

    assert string1.eql?(string2)
    assert_not string1.eql?(string3)
  end

  # Hash and Set operations

  test "#hash returns same value for equal strings" do
    string1 = NormalizedString.new("Hello")
    string2 = NormalizedString.new("hello")

    assert_equal string1.hash, string2.hash
  end

  test "#hash allows strings to work in Set" do
    string1 = NormalizedString.new("Hello")
    string2 = NormalizedString.new("hello")
    string3 = NormalizedString.new("world")

    set = Set.new
    set.add(string1)
    set.add(string2) # Should not be added due to duplicate
    set.add(string3)

    assert_equal 2, set.size
  end

  test "#hash allows strings to work as hash keys" do
    string1 = NormalizedString.new("Hello")
    string2 = NormalizedString.new("hello")

    hash = {}
    hash[string1] = "first"
    hash[string2] = "second"

    assert_equal 1, hash.size
    assert_equal "second", hash[string1]
  end

  # String methods

  test "#to_s returns the normalized string" do
    string = NormalizedString.new("  Hello  World  ")

    assert_equal "Hello World", string.to_s
  end

  test "#as_json returns the normalized string" do
    string = NormalizedString.new("  Hello  World  ")

    assert_equal "Hello World", string.as_json
  end

  test "#length returns length of normalized string" do
    string = NormalizedString.new("  hello  ")

    assert_equal 5, string.length
  end

  test "#length handles empty string" do
    string = NormalizedString.new("")

    assert_equal 0, string.length
  end

  test "#blank? returns true for empty string" do
    string = NormalizedString.new("")

    assert_predicate string, :blank?
  end

  test "#blank? returns true for whitespace-only string" do
    string = NormalizedString.new("   ")

    assert_predicate string, :blank?
  end

  test "#blank? returns false for non-empty string" do
    string = NormalizedString.new("hello")

    assert_not_predicate string, :blank?
  end

  # Edge cases and complex Unicode

  test "handles full-width characters" do
    string1 = NormalizedString.new("Ｈｅｌｌｏ") # Full-width
    string2 = NormalizedString.new("Hello") # Normal

    assert_equal string1, string2
  end

  test "handles accented characters" do
    string1 = NormalizedString.new("José")
    string2 = NormalizedString.new("Jose\u0301") # Combining accent

    assert_equal string1, string2
  end

  test "handles ligatures" do
    string = NormalizedString.new("ﬃ") # ffi ligature (U+FB03)

    # NFKC normalizes ligatures
    assert_equal "ffi", string.to_s
  end

  test "handles emoji" do
    string = NormalizedString.new("Hello 👋")

    assert_equal "Hello 👋", string.to_s
  end

  test "handles multiple consecutive spaces" do
    string = NormalizedString.new("hello     world")

    assert_equal "hello world", string.to_s
  end

  test "handles tabs and newlines" do
    string = NormalizedString.new("hello\t\nworld")

    assert_equal "hello world", string.to_s
  end
end
