# frozen_string_literal: true

require "test_helper"

class GlobalIdentityTest < ActiveSupport::TestCase
  test "#model_name returns the model's ActiveModel name" do
    assert_equal ::Game.model_name, game_identity.model_name
  end

  test "#to_key wraps the id in an array" do
    assert_equal ["g1"], game_identity.to_key
  end

  test "#to_param returns the id" do
    assert_equal "g1", game_identity.to_param
  end

  test "#to_global_id builds a GID from the model and id" do
    gid = game_identity.to_global_id

    assert_equal "Game", gid.model_name
    assert_equal "g1", gid.model_id
  end

  test "#to_global_id builds a Player GID for the Player model" do
    gid = GlobalIdentity.new(model: ::Player, id: "p1").to_global_id

    assert_equal "Player", gid.model_name
    assert_equal "p1", gid.model_id
  end

  test "#to_global_id uses the app option when given" do
    assert_equal "other", game_identity.to_global_id(app: "other").app
  end

  test "#to_gid_param encodes the GID URI" do
    decoded = Base64.urlsafe_decode64(game_identity.to_gid_param)

    assert_equal "gid://#{GlobalID.app}/Game/g1", decoded
  end

  private

  def game_identity
    GlobalIdentity.new(model: ::Game, id: "g1")
  end
end
