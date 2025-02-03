require "test_helper"

class LoadedQuestions::PlayersControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get loaded_questions_players_new_url
    assert_response :success
  end

  test "should get create" do
    get loaded_questions_players_create_url
    assert_response :success
  end

  test "should get edit" do
    get loaded_questions_players_edit_url
    assert_response :success
  end

  test "should get update" do
    get loaded_questions_players_update_url
    assert_response :success
  end
end
