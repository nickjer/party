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
        player_name = new_game.player_name #: ::PlayerName
        game = Game.build(question: new_game.question)
        game.add_player(user_id: current_user.id, name: player_name,
          guesser: true)
        repo.save(game)
        redirect_to loaded_questions_game_path(game.id)
      else
        render :new, locals: { new_game: }, status: :unprocessable_content
      end
    end

    # GET /loaded_questions/games/:id
    def show
      game = repo.find(params[:id])
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
          completed_round_form = CompletedRoundForm.new(game:)
          render :guessing_guesser,
            locals: { game:, current_player:, completed_round_form: }
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
      game = repo.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden if current_player.guesser?

      new_round = NewRoundForm.new(game:)
      render :new_round, locals: { game:, current_player:, new_round: }
    end

    # POST /loaded_questions/games/:id/create_round
    def create_round
      game = repo.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden if current_player.guesser?

      new_round = NewRoundForm.new(
        game:,
        question: new_round_params[:question]
      )

      if new_round.valid?
        game.start_new_round(question: new_round.question,
          guesser: current_player)
        repo.save(game)
        Broadcast::RoundCreated.new(game:).call

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
      game = repo.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden unless current_player.guesser?

      completed_round_form = CompletedRoundForm.new(game:)
      if completed_round_form.valid?
        game.complete_round
        repo.save(game)
        Broadcast::RoundCompleted.new(game:).call
        render :completed, locals: { game:, current_player: }
      else
        render :guessing_guesser,
          locals: { game:, current_player:, completed_round_form: },
          status: :unprocessable_content
      end
    end

    # PATCH /loaded_questions/games/:id/guessing_round
    def guessing_round
      game = repo.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden unless current_player.guesser?

      guessing_round_form = GuessingRoundForm.new(game:)
      if guessing_round_form.valid?
        game.begin_guessing
        repo.save(game)
        Broadcast::GuessingRoundStarted.new(game:).call
        completed_round_form = CompletedRoundForm.new(game:)
        render :guessing_guesser,
          locals: { game:, current_player:, completed_round_form: }
      else
        render :polling_guesser,
          locals: { game:, current_player:, guessing_round_form: },
          status: :unprocessable_content
      end
    end

    # PATCH /loaded_questions/games/:id/assign_guess
    def assign_guess
      game = repo.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden unless current_player.guesser?
      return head :forbidden unless game.status.guessing?

      player_id = assign_guess_params[:player_id]
      answer_id = assign_guess_params[:answer_id].presence

      game.assign_guess(player_id:, answer_id:)
      repo.save(game)
      Broadcast::GuessesUpdated.new(game:).call

      head :ok
    end

    private

    def new_game_params
      params.expect(game: %w[player_name question])
    end

    def new_round_params
      params.expect(round: %w[question])
    end

    def assign_guess_params
      params.expect(guess_assignment: %w[player_id answer_id])
    end

    def repo = GameRepo
  end
end
