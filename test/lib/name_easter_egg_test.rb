# frozen_string_literal: true

require "test_helper"

class NameEasterEggTest < ActiveSupport::TestCase
  test "#apply rewrites Bethany to Betsy" do
    assert_equal "Betsy", apply("Bethany")
  end

  test "#apply preserves lower-case casing" do
    assert_equal "betsy", apply("bethany")
  end

  test "#apply preserves upper-case casing" do
    assert_equal "BETSY", apply("BETHANY")
  end

  test "#apply rewrites only the matching word, keeping the rest" do
    assert_equal "🟥 Betsy betsy world!!", apply("🟥 Bethany bethany world!!")
  end

  test "#apply keeps emoji and symbols wrapping the name" do
    assert_equal "🎉Betsy🎉", apply("🎉Bethany🎉")
  end

  test "#apply sees through leetspeak substitutions" do
    assert_equal "Betsy", apply("B3th4ny")
    assert_equal "betsy", apply("8e7h4ny")
  end

  test "#apply sees through separators wedged between letters" do
    assert_equal "betsy", apply("b.e.t.h.a.n.y")
    assert_equal "betsy", apply("b e t h a n y")
    assert_equal "betsy", apply("b-e-t-h-a-n-y")
  end

  test "#apply sees through repeated letters" do
    assert_equal "Betsy", apply("Beethany")
    assert_equal "betsy", apply("bethanyyy")
  end

  test "#apply sees through look-alike glyphs" do
    cyrillic = "Bеthаnу" # B e(Cyrillic) t h a(Cyrillic) n y(Cyrillic)

    assert_equal "Betsy", apply(cyrillic)
  end

  test "#apply leaves unrelated names untouched" do
    assert_equal "Alice", apply("Alice")
    assert_equal "Elizabeth", apply("Elizabeth")
  end

  test "#apply does not rewrite Bethany embedded in a larger word" do
    assert_equal "Bethanyish", apply("Bethanyish")
  end

  private

  def apply(raw) = NameEasterEgg.new(raw).apply.to_s
end
