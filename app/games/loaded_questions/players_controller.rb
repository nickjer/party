# frozen_string_literal: true

module LoadedQuestions
  # Controller for player actions including joining games
  # and submitting answers.
  class PlayersController < ApplicationController
    # GET /games/:game_id/player/new
    def new
      game = repo.find(params[:game_id])
      current_player = game.player_for(current_user.id)

      if current_player
        redirect_to_game(game)
      else
        new_player = NewPlayerForm.new(game:, user_id: current_user.id)
        render :new, locals: { new_player: }
      end
    end

    # POST /games/:game_id/player
    def create
      game, new_player = repo.join(params[:game_id]) do |game|
        new_player = NewPlayerForm.new(game:, user_id: current_user.id,
          name: new_player_params[:name])
        if new_player.valid?
          name = new_player.player_name #: ::PlayerName
          game.add_player(user_id: current_user.id, name:)
        end
        new_player
      end

      if new_player.errors.empty?
        player = game.player_for!(current_user.id)
        Broadcast::PlayerCreated.new(game:, player:).call
        redirect_to_game(game)
      else
        render :new, locals: { new_player: }, status: :unprocessable_content
      end
    end

    # GET /games/:game_id/player/edit
    def edit
      game = repo.find(params[:game_id])
      current_player = game.player_for(current_user.id)
      return redirect_to_new_player(game) if current_player.nil?

      edit_player = EditPlayerForm.new(game:, current_player:)
      render :edit, locals: { game:, current_player:, edit_player: }
    end

    # PATCH/PUT /games/:game_id/player
    def update
      user_id = current_user.id
      game, current_player, edit_player =
        repo.update(params[:game_id], user_id:) do |game, current_player|
          edit_player = EditPlayerForm.new(game:, current_player:,
            name: update_player_params[:name])
          if edit_player.valid?
            new_name = edit_player.player_name #: ::PlayerName
            current_player.name = new_name
          end
          edit_player
        end

      if edit_player.errors.empty?
        Broadcast::PlayerNameUpdated.new(game:, player: current_player).call
        redirect_to_game(game)
      else
        render :edit, locals: { game:, current_player:, edit_player: },
          status: :unprocessable_content
      end
    end

    # PATCH /games/:game_id/player/answer
    def answer
      answer_form = AnswerForm.new(answer: answer_params[:answer])
      valid = answer_form.valid?
      user_id = current_user.id
      game, current_player, had_answer =
        repo.update(params[:game_id], user_id:) do |_game, current_player|
          had_answer = current_player.answered?
          current_player.answer = answer_form.answer if valid
          had_answer
        end

      if valid && !had_answer
        Broadcast::AnswerCreated.new(game:, player: current_player).call
      end

      status = valid ? :ok : :unprocessable_content
      render "loaded_questions/games/polling_player",
        locals: { game:, current_player:, answer_form: },
        status:
    end

    private

    def new_player_params
      params.expect(player: %w[name])
    end

    def update_player_params
      params.expect(player: %w[name])
    end

    def answer_params
      params.expect(player: %w[answer])
    end

    def redirect_to_game(game)
      redirect_to(loaded_questions_game_path(game.id))
    end

    def redirect_to_new_player(game)
      redirect_to(new_loaded_questions_game_player_path(game.id))
    end

    def repo = GameRepo
  end
end
