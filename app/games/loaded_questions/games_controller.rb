# frozen_string_literal: true

module LoadedQuestions
  class GamesController < ::ApplicationController
    # GET /loaded_questions/games/new
    def new
      @new_game = NewGameForm.new
    end

    # POST /loaded_questions/games/create
    def create
      @new_game = NewGameForm.new(params:new_game_params)

      if @new_game.valid?
        game = NewGame.new(
          user: current_user,
          player_name: @new_game.player_name,
          question: @new_game.question,
          hide_answers: @new_game.hide_answers
        ).build
        game.save!
        redirect_to loaded_questions_game_path(game.slug)
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /loaded_questions/games/:id
    def show
      @game = Game.find(params[:id])
    end

    private

    def new_game_params
      params.expect(game: %w[player_name question hide_answers])
    end
  end
end
