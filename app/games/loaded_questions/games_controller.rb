# frozen_string_literal: true

module LoadedQuestions
  class GamesController < ::ApplicationController
    # GET /loaded_questions/games/new
    def new
      @new_game = NewGameForm.new
      render :new
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
        @new_game = new_game
        render :new, status: :unprocessable_content
      end
    end

    # GET /loaded_questions/games/:id
    def show
      @game = Game.find(params[:id])
      current_player = @game.player_for(current_user)

      if current_player.nil?
        redirect_to(new_loaded_questions_game_player_path(@game.slug))
      else
        @current_player = current_player

        case @game.status
        when Game::Status.polling
          if current_player.guesser?
            guessing_round_form = GuessingRoundForm.new(game: @game)
            render :polling_guesser, locals: { guessing_round_form: }
          else
            answer_form = AnswerForm.new(answer: current_player.answer)
            render :polling_player, locals: { answer_form: }
          end
        when Game::Status.guessing
          if current_player.guesser?
            render :guessing_guesser
          else
            render :guessing_player
          end
        when Game::Status.completed
          render :completed
        end
      end
    end

    # GET /loaded_questions/games/:id/players
    def players
      @game = Game.find(params[:id])
      @current_player = @game.player_for!(current_user)
    end

    # PATCH /loaded_questions/games/:id/completed_round
    def completed_round
      @game = Game.find(params[:id])
      @current_player = @game.player_for!(current_user)
      return (head :forbidden) unless @current_player.guesser?

      completed_round_form = CompletedRoundForm.new(game: @game)
      if completed_round_form.valid?
        @game.update_status(Game::Status.completed)
        @game.broadcast_reload_game
        redirect_to loaded_questions_game_path(@game.slug)
      else
        render :guessing_guesser, locals: { completed_round_form: }, status: :unprocessable_content
      end
    end

    # PATCH /loaded_questions/games/:id/guessing_round
    def guessing_round
      @game = Game.find(params[:id])
      @current_player = @game.player_for!(current_user)
      return (head :forbidden) unless @current_player.guesser?

      guessing_round_form = GuessingRoundForm.new(game: @game)
      if guessing_round_form.valid?
        @game.update_status(Game::Status.guessing)
        target = loaded_questions_game_path(@game.slug)
        @game.broadcast_reload_game
        head :ok
      else
        render :polling_guesser, locals: { guessing_round_form: }, status: :unprocessable_content
      end
    end

    # PATCH /loaded_questions/games/:id/swap_guesses
    def swap_guesses
      @game = Game.find(params[:id])
      @current_player = @game.player_for!(current_user)
      return (head :forbidden) unless @current_player.guesser?
      return (head :forbidden) unless @game.status.guessing?

      player_id_1 = swap_params[:guess_id].to_i
      player_id_2 = swap_params[:swap_guess_id].to_i

      @game.swap_guesses(player_id_1:, player_id_2:)

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
