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
      user_id = current_user.id
      game, current_player, start_game =
        repo.update(params[:id], user_id:) do |game, current_player|
          game.require_starting_spymaster(current_player)
          start_game = StartGameForm.new(game:)
          game.start_game(player: current_player) if start_game.valid?
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
      clue_params = submit_clue_params
      game, current_player, clue_form =
        repo.update(params[:id], user_id:) do |game, current_player|
          clue_form = ClueForm.new(word: clue_params[:word],
            number: clue_params[:number])
          if clue_form.valid?
            game.submit_clue(player: current_player, word: clue_form.word,
              number: clue_form.parsed_number)
          end
          clue_form
        end

      if clue_form.errors.empty?
        Broadcast::BoardUpdated.new(game:, player: current_player).call
        render :play, locals: { game:, current_player: }
      else
        render :play, locals: { game:, current_player:, clue_form: },
          status: :unprocessable_content
      end
    end

    def reveal
      index = Integer(reveal_params[:index], exception: false)
      return head :forbidden if index.nil?

      user_id = current_user.id
      game, current_player =
        repo.update(params[:id], user_id:) do |game, current_player|
          game.reveal(player: current_player, index:)
        end
      Broadcast::BoardUpdated.new(game:, player: current_player).call
      render :play, locals: { game:, current_player: }
    end

    def pass
      user_id = current_user.id
      game, current_player =
        repo.update(params[:id], user_id:) do |game, current_player|
          game.pass_turn(player: current_player)
        end
      Broadcast::BoardUpdated.new(game:, player: current_player).call
      render :play, locals: { game:, current_player: }
    end

    def new_game
      user_id = current_user.id
      game, current_player =
        repo.update(params[:id], user_id:) do |game, _current_player|
          game.start_new_game(words: Words.instance.sample)
        end
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

    def submit_clue_params
      params.expect(clue: %w[word number])
    end

    def repo = GameRepo
  end
end
