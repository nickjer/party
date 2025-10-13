require "test_helper"

module LoadedQuestions
  class PlayersControllerTest < ActionDispatch::IntegrationTest
    test "#answer returns unprocessable_content with validation error for single letter answer" do
      # Create game with guesser and one additional player
      game = create(:loaded_questions_game, players: [ "Bob" ])
      bob = game.players.find { |p| p.name.to_s == "Bob" }

      # Create an encrypted cookie using ActionDispatch::TestRequest
      test_request = ActionDispatch::TestRequest.create
      test_request.cookie_jar.encrypted[:current_user_id] = bob.user.id
      cookies[:current_user_id] = test_request.cookie_jar[:current_user_id]

      # Submit a single-letter answer (should fail validation)
      patch answer_loaded_questions_game_player_path(game.slug), params: {
        player: {
          answer: "A"
        }
      }

      # Assert validation error response
      assert_response :unprocessable_content
      assert_select "textarea[name='player[answer]']"
      assert_match(/is too short/, response.body)
    end
  end
end
