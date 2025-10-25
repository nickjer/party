# frozen_string_literal: true

module LoadedQuestions
  # Controller for Loaded Questions game actions including creation, viewing,
  # and phase transitions.
  class GamesController < ::ApplicationController
    # GET /loaded_questions/games/new
    def new
      new_game = NewGameForm.new
      render :new, locals: { new_game: }
    end

    # POST /loaded_questions/games/create
    def create
      new_game = NewGameForm.new(
        player_name: new_game_params[:player_name],
        question: new_game_params[:question]
      )

      if new_game.valid?
        game = CreateNewGame.new(
          user_id: current_user.id,
          player_name: new_game.player_name,
          question: new_game.question
        ).call
        game.save!
        redirect_to loaded_questions_game_path(game.id)
      else
        render :new, locals: { new_game: }, status: :unprocessable_content
      end
    end

    # GET /loaded_questions/games/:id
    def show
      game = Game.find(params[:id])
      current_player = game.player_for(current_user.id)

      if current_player.nil?
        redirect_to(new_loaded_questions_game_player_path(game.id))
        return
      end

      case game.status
      when Game::Status.polling
        if current_player.guesser?
          guessing_round_form = GuessingRoundForm.new(game:)
          render :polling_guesser,
            locals: { game:, current_player:, guessing_round_form: }
        else
          answer_form = AnswerForm.new(answer: current_player.answer)
          render :polling_player,
            locals: { game:, current_player:, answer_form: }
        end
      when Game::Status.guessing
        if current_player.guesser?
          render :guessing_guesser, locals: { game:, current_player: }
        else
          render :guessing_player, locals: { game:, current_player: }
        end
      when Game::Status.completed
        render :completed, locals: { game:, current_player: }
      else
        raise "Unknown game status: #{game.status}"
      end
    end

    # GET /loaded_questions/games/:id/new_round
    def new_round
      game = Game.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden if current_player.guesser?

      new_round = NewRoundForm.new(game:)
      render :new_round, locals: { game:, current_player:, new_round: }
    end

    # POST /loaded_questions/games/:id/create_round
    def create_round
      game = Game.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden if current_player.guesser?

      new_round = NewRoundForm.new(
        game:,
        question: new_round_params[:question]
      )

      if new_round.valid?
        CreateNewRound.new(
          game:,
          guesser: current_player,
          question: new_round.question
        ).call
        game.save!
        Broadcast::RoundCreated.new(game:).call

        game = Game.find(params[:id])
        current_player = game.player_for!(current_user.id)
        guessing_round_form = GuessingRoundForm.new(game:)
        render :polling_guesser,
          locals: { game:, current_player:, guessing_round_form: }
      else
        render :new_round, locals: { game:, current_player:, new_round: },
          status: :unprocessable_content
      end
    end

    # PATCH /loaded_questions/games/:id/completed_round
    def completed_round
      game = Game.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden unless current_player.guesser?

      completed_round_form = CompletedRoundForm.new(game:)
      if completed_round_form.valid?
        CompleteRound.new(game:).call
        game.save!
        Broadcast::RoundCompleted.new(game:).call
        render :completed, locals: { game:, current_player: }
      else
        render :guessing_guesser, locals: { game:, current_player: },
          status: :unprocessable_content
      end
    end

    # PATCH /loaded_questions/games/:id/guessing_round
    def guessing_round
      game = Game.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden unless current_player.guesser?

      guessing_round_form = GuessingRoundForm.new(game:)
      if guessing_round_form.valid?
        BeginGuessingRound.new(game:).call
        game.save!
        Broadcast::GuessingRoundStarted.new(game:).call
        render :guessing_guesser, locals: { game:, current_player: }
      else
        render :polling_guesser,
          locals: { game:, current_player:, guessing_round_form: },
          status: :unprocessable_content
      end
    end

    # PATCH /loaded_questions/games/:id/swap_guesses
    def swap_guesses
      game = Game.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden unless current_player.guesser?
      return head :forbidden unless game.status.guessing?

      player_id1 = swap_params[:guess_id]
      player_id2 = swap_params[:swap_guess_id]

      game.swap_guesses(player_id1:, player_id2:)
      game.save!
      Broadcast::AnswersSwapped.new(game:).call

      head :ok
    end

    private

    def new_game_params
      params.expect(game: %w[player_name question])
    end

    def new_round_params
      params.expect(round: %w[question])
    end

    def swap_params
      params.expect(guess_swapper: %w[guess_id swap_guess_id])
    end
  end
end
