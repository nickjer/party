# frozen_string_literal: true

module BurnUnit
  # Controller for managing Burn Unit players
  class PlayersController < ApplicationController
    def new
      game = Game.find(params[:game_id])
      current_player = game.player_for(current_user.id)

      if current_player
        redirect_to_game(game)
      else
        new_player = NewPlayerForm.new(game:, user_id: current_user.id)
        render :new, locals: { new_player: }
      end
    end

    def create
      game = Game.find(params[:game_id])
      new_player = NewPlayerForm.new(game:, user_id: current_user.id,
        name: new_player_params[:name])

      if new_player.valid?
        game.add_player(
          user_id: current_user.id,
          name: new_player.name
        )
        game.save!

        redirect_to_game(game)
      else
        render :new, locals: { new_player: }, status: :unprocessable_content
      end
    end

    def edit
      game = Game.find(params[:game_id])
      current_player = game.player_for(current_user.id)
      return redirect_to_new_player(game) if current_player.nil?

      edit_player = EditPlayerForm.new(game:, current_player:)
      render :edit, locals: { game:, current_player:, edit_player: }
    end

    def update
      game = Game.find(params[:game_id])
      current_player = game.player_for(current_user.id)
      return redirect_to_new_player(game) if current_player.nil?

      edit_player = EditPlayerForm.new(game:, current_player:,
        name: update_player_params[:name])
      if edit_player.valid?
        current_player.name = edit_player.name
        current_player.save!
        Broadcast::PlayerNameUpdated.new(game:, player: current_player).call
        redirect_to_game(game)
      else
        render :edit, locals: { game:, current_player:, edit_player: },
          status: :unprocessable_content
      end
    end

    def vote
      game = Game.find(params[:game_id])
      current_player = game.player_for(current_user.id)
      return redirect_to_new_player(game) if current_player.nil?

      vote_form = VoteForm.new(game:, current_player:,
        candidate_id: vote_params[:candidate_id])
      if vote_form.valid?
        had_vote = current_player.voted?
        current_player.vote = vote_form.candidate_id
        current_player.save!
        unless had_vote
          Broadcast::VoteCreated.new(game:,
            player: current_player).call
        end
      end

      status = vote_form.valid? ? :ok : :unprocessable_content
      if current_player.judge?
        completed_round_form = CompletedRoundForm.new(game:)
        render "burn_unit/games/polling_judge",
          locals: { game:, current_player:, vote_form:, completed_round_form: },
          status:
      else
        render "burn_unit/games/polling_player",
          locals: { game:, current_player:, vote_form: },
          status:
      end
    end

    private

    def new_player_params
      params.expect(player: %w[name])
    end

    def update_player_params
      params.expect(player: %w[name])
    end

    def vote_params
      params.expect(player: %w[candidate_id])
    end

    def redirect_to_game(game)
      redirect_to(burn_unit_game_path(game.id))
    end

    def redirect_to_new_player(game)
      redirect_to(new_burn_unit_game_player_path(game.id))
    end
  end
end
