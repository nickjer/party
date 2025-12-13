# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "#index renders home page successfully" do
    get root_path

    assert_response :success
  end

  test "#index displays Loaded Questions game card" do
    get root_path

    assert_response :success
    assert_dom "h2", text: "Loaded Questions"
    assert_dom "a[href='#{new_loaded_questions_game_path}']",
      text: /Start New Game/
  end

  test "#index displays Burn Unit game card" do
    get root_path

    assert_response :success
    assert_dom "h2", text: "Burn Unit"
    assert_dom "a[href='#{new_burn_unit_game_path}']", text: /Start New Game/
  end

  test "#index displays page title" do
    get root_path

    assert_response :success
    assert_dom "h1", text: /Party/
  end
end
