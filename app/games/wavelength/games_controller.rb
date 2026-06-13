# frozen_string_literal: true

module Wavelength
  # Controller for managing Wavelength games.
  class GamesController < ::ApplicationController
    def new
      render :new, locals: { new_game: NewGameForm.new }
    end

    def create
      new_game = NewGameForm.new(player_name: new_game_params[:player_name])

      if new_game.valid?
        player_name = new_game.player_name #: ::PlayerName
        game = Game.build(spectrum: Spectrums.instance.sample,
          target: Game::Target.generate)
        game.add_player(user_id: current_user.id, name: player_name)
        repo.save(game)
        redirect_to wavelength_game_path(game.id)
      else
        render :new, locals: { new_game: }, status: :unprocessable_content
      end
    end

    def show
      game = repo.find(params[:id])
      current_player = game.player_for(current_user.id)
      if current_player.nil?
        return redirect_to(new_wavelength_game_player_path(game.id))
      end

      case game.status
      when Game::Status.setup
        start_game = StartGameForm.new(game:)
        render :lobby, locals: { game:, current_player:, start_game: }
      else
        if current_player.team.nil? && !game.status.completed?
          join_team = JoinTeamForm.new(game:, current_player:)
          render :join_team, locals: { game:, current_player:, join_team: }
        else
          render :play, locals: { game:, current_player: }
        end
      end
    end

    def start
      game = repo.find(params[:id])
      current_player = game.player_for!(current_user.id)

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

    def move_dial
      game = repo.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden unless game.status.guessing?
      return head :forbidden if current_player.team != game.current_team
      return head :forbidden if game.psychic?(current_player)

      position = Integer(move_dial_params[:position], exception: false)
      return head :forbidden if position.nil? || !position.between?(0, 100)

      game.move_dial(position:)
      repo.save(game)
      Broadcast::DialMoved.new(game:, player: current_player).call
      head :no_content
    end

    def lock_guess
      game = repo.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden unless game.status.guessing?
      return head :forbidden if current_player.team != game.current_team
      return head :forbidden if game.psychic?(current_player)

      position = Integer(lock_guess_params[:position], exception: false)
      return head :forbidden if position.nil? || !position.between?(0, 100)

      game.lock_guess(position:)
      repo.save(game)
      Broadcast::RoundUpdated.new(game:, player: current_player).call
      render :play, locals: { game:, current_player: }
    end

    def guess_side
      game = repo.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden unless game.status.left_right?
      if current_player.team != game.current_team.opponent
        return head :forbidden
      end

      side = guess_side_params[:side]
      return head :forbidden unless %w[left right].include?(side)

      game.guess_side(side:)
      repo.save(game)
      Broadcast::RoundUpdated.new(game:, player: current_player).call
      render :play, locals: { game:, current_player: }
    end

    def next_round
      game = repo.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden unless game.status.reveal?

      game.start_new_round(spectrum: Spectrums.instance.sample,
        target: Game::Target.generate)
      repo.save(game)
      Broadcast::RoundUpdated.new(game:, player: current_player).call
      render :play, locals: { game:, current_player: }
    end

    def new_game
      game = repo.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden unless game.status.completed?

      game.start_new_game(spectrum: Spectrums.instance.sample,
        target: Game::Target.generate)
      repo.save(game)
      Broadcast::NewGameStarted.new(game:, player: current_player).call
      start_game = StartGameForm.new(game:)
      render :lobby, locals: { game:, current_player:, start_game: }
    end

    private

    def new_game_params = params.expect(game: %w[player_name])
    def move_dial_params = params.expect(guess: %w[position])
    def lock_guess_params = params.expect(guess: %w[position])
    def guess_side_params = params.expect(guess: %w[side])

    def repo = GameRepo
  end
end
