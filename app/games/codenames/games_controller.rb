# frozen_string_literal: true

module Codenames
  # Controller for managing Codenames games
  class GamesController < ::ApplicationController
    def new
      new_game = NewGameForm.new
      render :new, locals: { new_game: }
    end

    def create
      new_game = NewGameForm.new(player_name: new_game_params[:player_name])

      if new_game.valid?
        player_name = new_game.player_name #: ::PlayerName
        game = Game.build(words: Words.instance.sample)
        game.add_player(user_id: current_user.id, name: player_name)
        repo.save(game)
        redirect_to codenames_game_path(game.id)
      else
        render :new, locals: { new_game: }, status: :unprocessable_content
      end
    end

    def show
      game = repo.find(params[:id])
      current_player = game.player_for(current_user.id)

      if current_player.nil?
        redirect_to(new_codenames_game_player_path(game.id))
        return
      end

      case game.status
      when Game::Status.setup
        start_game = StartGameForm.new(game:)
        render :lobby, locals: { game:, current_player:, start_game: }
      when Game::Status.playing
        if current_player.team.nil?
          join_team = JoinTeamForm.new(game:, current_player:)
          render :join_team, locals: { game:, current_player:, join_team: }
        else
          render :play, locals: { game:, current_player: }
        end
      when Game::Status.completed
        render :play, locals: { game:, current_player: }
      else
        raise "Unknown game status: #{game.status}"
      end
    end

    def start
      game = repo.find(params[:id])
      current_player = game.player_for!(current_user.id)
      if current_player != game.spymaster_for(game.starting_team)
        return head :forbidden
      end

      start_game = StartGameForm.new(game:)
      if start_game.valid?
        game.start_game
        repo.save(game)
        Broadcast::GameStarted.new(game:, player: current_player).call
        render :play, locals: { game:, current_player: }
      else
        render :lobby, locals: { game:, current_player:, start_game: },
          status: :unprocessable_content
      end
    end

    def reveal
      game = repo.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden unless game.status.playing?
      return head :forbidden unless current_player.operative?
      return head :forbidden if current_player.team != game.current_team

      index = reveal_params[:index].to_i
      return head :forbidden unless revealable?(game, index)

      game.reveal(index:)
      repo.save(game)
      Broadcast::BoardUpdated.new(game:, player: current_player).call
      render :play, locals: { game:, current_player: }
    end

    def pass
      game = repo.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden unless game.status.playing?
      return head :forbidden unless current_player.operative?
      return head :forbidden if current_player.team != game.current_team

      game.pass_turn
      repo.save(game)
      Broadcast::BoardUpdated.new(game:, player: current_player).call
      render :play, locals: { game:, current_player: }
    end

    def new_game
      game = repo.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden unless game.status.completed?

      game.start_new_game(words: Words.instance.sample)
      repo.save(game)
      Broadcast::NewGameStarted.new(game:, player: current_player).call

      start_game = StartGameForm.new(game:)
      render :lobby, locals: { game:, current_player:, start_game: }
    end

    private

    def new_game_params
      params.expect(game: %w[player_name])
    end

    def reveal_params
      params.expect(reveal: %w[index])
    end

    def revealable?(game, index)
      index.between?(0, Game::Board::SIZE - 1) &&
        !game.board.card(index).revealed?
    end

    def repo = @repo ||= GameRepo.new
  end
end
