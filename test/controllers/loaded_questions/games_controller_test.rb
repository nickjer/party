require "test_helper"

class LoadedQuestions::GamesControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get loaded_questions_games_new_url
    assert_response :success
  end

  test "should get create" do
    get loaded_questions_games_create_url
    assert_response :success
  end

  test "should get show" do
    get loaded_questions_games_show_url
    assert_response :success
  end
end
