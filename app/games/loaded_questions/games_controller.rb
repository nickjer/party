# frozen_string_literal: true

module LoadedQuestions
  class GamesController < ::ApplicationController
    # GET /loaded_questions/games/new
    def new
      @new_game = NewGameForm.new
    end

    # POST /loaded_questions/games/create
    def create
    end

    # GET /loaded_questions/games/:id
    def show
    end

    private

    def new_game_params
      params.expect(:player_name, :question, :hide_answers)
    end
  end
end
