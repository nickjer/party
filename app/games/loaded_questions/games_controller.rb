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
        question: new_game_params[:question],
        hide_answers: new_game_params[:hide_answers]
      )

      if new_game.valid?
        game = NewGame.new(
          user: current_user,
          player_name: new_game.player_name,
          question: new_game.question,
          hide_answers: new_game.hide_answers
        ).build
        game.save!
        redirect_to loaded_questions_game_path(game.slug)
      else
        @new_game = new_game
        render :new, status: :unprocessable_entity
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
            match_form = MatchForm.new(game: @game)
            render :polling, locals: { match_form: }
          else
            answer_form = AnswerForm.new(answer: current_player.answer)
            render :polling, locals: { answer_form: }
          end
        when Game::Status.matching
          render :matching
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

    # PATCH /loaded_questions/games/:id/match
    def match
      @game = Game.find(params[:id])
      @current_player = @game.player_for!(current_user)

      if @current_player.guesser?
        match_form = MatchForm.new(game: @game)
        if match_form.valid?
        else
          render "loaded_questions/games/polling", locals: { match_form: }
        end
      else
        head :forbidden
      end
    end

    private

    def new_game_params
      params.expect(game: %w[player_name question hide_answers])
    end
  end
end
