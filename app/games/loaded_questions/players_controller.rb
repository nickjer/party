# frozen_string_literal: true

module LoadedQuestions
  class PlayersController < ApplicationController
    # GET /games/:game_id/players/new
    def new
      game = Game.find(params[:game_id])

      if game.player_for(current_user)
        redirect_to loaded_questions_game_path(game.slug)
      else
        @new_player = NewPlayerForm.new(game:)
        render :new
      end
    end

    # POST /games/:game_id/players
    def create
      game = Game.find(params[:game_id])
      new_player = NewPlayerForm.new(game:, params: new_player_params)

      if new_player.valid?
        player = NewPlayer.new(
          user: current_user,
          name: new_player.name,
          guesser: false
        ).build
        player.game_id = game.id
        player.save!

        ::Turbo::StreamsChannel.broadcast_refresh_to(game)
        redirect_to loaded_questions_game_path(game.slug)
      else
        @new_player = new_player
        render :new, status: :unprocessable_entity
      end
    end

    # GET /games/:game_id/players/:id/edit
    def edit
    end

    # PATCH/PUT /games/:game_id/players/:id
    def update
    end

    private

    def new_player_params
      params.expect(player: %w[name])
    end
  end
end
