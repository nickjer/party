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
        game = NewGame.new(
          user: current_user,
          player_name: new_game.player_name,
          question: new_game.question
        ).build
        game.save!
        redirect_to loaded_questions_game_path(game.slug)
      else
        render :new, locals: { new_game: }, status: :unprocessable_content
      end
    end

    # GET /loaded_questions/games/:id
    def show
      game = Game.from_slug(params[:id])
      current_player = game.player_for(current_user)

      if current_player.nil?
        redirect_to(new_loaded_questions_game_player_path(game.slug))
      else
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
        end
      end
    end

    # GET /loaded_questions/games/:id/new_round
    def new_round
      game = Game.from_slug(params[:id])
      current_player = game.player_for!(current_user)
      return head :forbidden if current_player.guesser?

      new_round = NewRoundForm.new(game:)
      render :new_round, locals: { game:, current_player:, new_round: }
    end

    # GET /loaded_questions/games/:id/players
    def players
      game = Game.from_slug(params[:id])
      current_player = game.player_for!(current_user)
      render locals: { game:, current_player: }
    end

    # PATCH /loaded_questions/games/:id/completed_round
    def completed_round
      game = Game.from_slug(params[:id])
      current_player = game.player_for!(current_user)
      return head :forbidden unless current_player.guesser?

      completed_round_form = CompletedRoundForm.new(game:)
      if completed_round_form.valid?
        game.update_status(Game::Status.completed)
        game.broadcast_reload_game
        redirect_to loaded_questions_game_path(game.slug)
      else
        render :guessing_guesser, locals: { game:, current_player: },
          status: :unprocessable_content
      end
    end

    # PATCH /loaded_questions/games/:id/guessing_round
    def guessing_round
      game = Game.from_slug(params[:id])
      current_player = game.player_for!(current_user)
      return head :forbidden unless current_player.guesser?

      guessing_round_form = GuessingRoundForm.new(game:)
      if guessing_round_form.valid?
        game.update_status(Game::Status.guessing)
        loaded_questions_game_path(game.slug)
        game.broadcast_reload_game
        head :ok
      else
        render :polling_guesser,
          locals: { game:, current_player:, guessing_round_form: },
          status: :unprocessable_content
      end
    end

    # PATCH /loaded_questions/games/:id/swap_guesses
    def swap_guesses
      game = Game.from_slug(params[:id])
      current_player = game.player_for!(current_user)
      return head :forbidden unless current_player.guesser?
      return head :forbidden unless game.status.guessing?

      player_id1 = swap_params[:guess_id].to_i
      player_id2 = swap_params[:swap_guess_id].to_i

      game.swap_guesses(player_id1:, player_id2:)
      game.broadcast_reload_game

      head :ok
    end

    private

    def new_game_params
      params.expect(game: %w[player_name question])
    end

    def swap_params
      params.expect(guess_swapper: %w[guess_id swap_guess_id])
    end
  end
end
