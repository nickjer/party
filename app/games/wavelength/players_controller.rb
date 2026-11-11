# frozen_string_literal: true

module Wavelength
  # Controller for managing Wavelength players
  class PlayersController < ApplicationController
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

    def edit
      game = repo.find(params[:game_id])
      current_player = game.player_for(current_user.id)
      return redirect_to_new_player(game) if current_player.nil?

      edit_player = EditPlayerForm.new(game:, current_player:)
      render :edit, locals: { game:, current_player:, edit_player: }
    end

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

    def join_team
      user_id = current_user.id
      game, current_player, join_team =
        repo.update(params[:game_id], user_id:) do |game, current_player|
          join_team = JoinTeamForm.new(game:, current_player:,
            team: join_team_params[:team])
          if join_team.valid?
            team = join_team.team #: Team
            game.join_team(player: current_player, team:)
          end
          join_team
        end

      if join_team.errors.empty?
        Broadcast::TeamUpdated.new(game:, player: current_player).call
        redirect_to_game(game)
      elsif game.status.setup?
        start_game = StartGameForm.new(game:)
        render "wavelength/games/lobby",
          locals: { game:, current_player:, start_game:, join_team: },
          status: :unprocessable_content
      else
        render "wavelength/games/join_team",
          locals: { game:, current_player:, join_team: },
          status: :unprocessable_content
      end
    end

    private

    def new_player_params
      params.expect(player: %w[name])
    end

    def update_player_params
      params.expect(player: %w[name])
    end

    def join_team_params
      params.expect(player: %w[team])
    end

    def redirect_to_game(game)
      redirect_to(wavelength_game_path(game.id))
    end

    def redirect_to_new_player(game)
      redirect_to(new_wavelength_game_player_path(game.id))
    end

    def repo = GameRepo
  end
end
