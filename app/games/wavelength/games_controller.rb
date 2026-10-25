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
      user_id = current_user.id
      game, current_player, start_game =
        repo.update(params[:id], user_id:) do |game, current_player|
          game.require_starting_team(current_player)
          start_game = StartGameForm.new(game:)
          game.start_game(psychic: current_player) if start_game.valid?
          start_game
        end

      if start_game.errors.empty?
        Broadcast::GameStarted.new(game:, player: current_player).call
        render :play, locals: { game:, current_player: }
      else
        render :lobby, locals: { game:, current_player:, start_game: },
          status: :unprocessable_content
      end
    end

    def submit_clue
      user_id = current_user.id
      game, current_player, clue =
        repo.update(params[:id], user_id:) do |game, current_player|
          clue = ClueForm.new(text: submit_clue_params[:text])
          if clue.valid?
            game.submit_clue(player: current_player,
              text: clue.text)
          end
          clue
        end

      if clue.errors.empty?
        Broadcast::RoundUpdated.new(game:, player: current_player).call
        render :play, locals: { game:, current_player: }
      else
        render :play, locals: { game:, current_player:, clue_form: clue },
          status: :unprocessable_content
      end
    end

    def move_dial
      position = Integer(move_dial_params[:position], exception: false)
      return head :forbidden if position.nil?

      user_id = current_user.id
      game, current_player =
        repo.update(params[:id], user_id:) do |game, current_player|
          game.move_dial(player: current_player, position:)
        end
      Broadcast::DialMoved.new(game:, player: current_player).call
      head :no_content
    end

    def lock_guess
      position = Integer(lock_guess_params[:position], exception: false)
      return head :forbidden if position.nil?

      user_id = current_user.id
      game, current_player =
        repo.update(params[:id], user_id:) do |game, current_player|
          game.lock_guess(player: current_player, position:)
        end
      Broadcast::RoundUpdated.new(game:, player: current_player).call
      render :play, locals: { game:, current_player: }
    end

    def guess_side
      side = guess_side_params[:side]
      user_id = current_user.id
      game, current_player =
        repo.update(params[:id], user_id:) do |game, current_player|
          game.guess_side(player: current_player, side:)
        end
      Broadcast::RoundUpdated.new(game:, player: current_player).call
      render :play, locals: { game:, current_player: }
    end

    def next_round
      user_id = current_user.id
      game, current_player =
        repo.update(params[:id], user_id:) do |game, current_player|
          game.start_new_round(psychic: current_player,
            spectrum: Spectrums.instance.sample, target: Game::Target.generate)
        end
      Broadcast::RoundUpdated.new(game:, player: current_player).call
      render :play, locals: { game:, current_player: }
    end

    def new_game
      user_id = current_user.id
      game, current_player =
        repo.update(params[:id], user_id:) do |game, _current_player|
          game.start_new_game(spectrum: Spectrums.instance.sample,
            target: Game::Target.generate)
        end
      Broadcast::NewGameStarted.new(game:, player: current_player).call
      start_game = StartGameForm.new(game:)
      render :lobby, locals: { game:, current_player:, start_game: }
    end

    private

    def new_game_params = params.expect(game: %w[player_name])
    def submit_clue_params = params.expect(clue: %w[text])
    def move_dial_params = params.expect(guess: %w[position])
    def lock_guess_params = params.expect(guess: %w[position])
    def guess_side_params = params.expect(guess: %w[side])

    def repo = GameRepo
  end
end
