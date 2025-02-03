# frozen_string_literal: true

module LoadedQuestions
  class PlayersController < ApplicationController
    # GET /games/:game_id/players/new
    def new
      game = Game.find(params[:game_id])
      @new_player = NewPlayerForm.new(game:)
    end

    # POST /games/:game_id/players
    def create
    end

    # GET /games/:game_id/players/:id/edit
    def edit
    end

    # PATCH/PUT /games/:game_id/players/:id
    def update
    end
  end
end
