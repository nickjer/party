# frozen_string_literal: true

module LoadedQuestions
  # Controller for player actions including joining games
  # and submitting answers.
  class PlayersController < ApplicationController
    # GET /games/:game_id/player/new
    def new
      game = Game.find(params[:game_id])
      current_player = game.player_for(current_user)

      if current_player
        redirect_to_game(game)
      else
        @new_player = NewPlayerForm.new(game:, user: current_user)
        render :new
      end
    end

    # POST /games/:game_id/player
    def create
      game = Game.find(params[:game_id])
      new_player = NewPlayerForm.new(game:, user: current_user,
        name: new_player_params[:name])

      if new_player.valid?
        player = NewPlayer.from(new_player).build
        player.game_id = game.id
        player.save!

        game.broadcast_render("loaded_questions/players/create",
          except_id: player.id)

        redirect_to_game(game)
      else
        @new_player = new_player
        render :new, status: :unprocessable_content
      end
    end

    # GET /games/:game_id/player/edit
    def edit; end

    # PATCH/PUT /games/:game_id/player
    def update; end

    # PATCH /games/:game_id/player/answer
    def answer
      game = Game.find(params[:game_id])
      current_player = game.player_for(current_user)
      return redirect_to_new_player(game) if current_player.nil?

      answer_form = AnswerForm.new(answer: answer_params[:answer])
      if answer_form.valid?
        current_player.update_answer(answer_form.answer)
        game.broadcast_reload_players
        redirect_to_game(game)
      else
        @game = game
        @current_player = current_player

        render "loaded_questions/games/polling_player",
          locals: { answer_form: }, status: :unprocessable_content
      end
    end

    private

    def new_player_params
      params.expect(player: %w[name])
    end

    def answer_params
      params.expect(player: %w[answer])
    end

    def redirect_to_game(game)
      redirect_to(loaded_questions_game_path(game.slug))
    end

    def redirect_to_new_player(game)
      redirect_to(new_loaded_questions_game_player_path(game.slug))
    end
  end
end
