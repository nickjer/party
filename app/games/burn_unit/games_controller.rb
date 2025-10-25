# frozen_string_literal: true

module BurnUnit
  # Controller for managing Burn Unit games
  class GamesController < ::ApplicationController
    def new
      new_game = NewGameForm.new
      render :new, locals: { new_game: }
    end

    def create
      new_game = NewGameForm.new(
        player_name: new_game_params[:player_name],
        question: new_game_params[:question]
      )

      if new_game.valid?
        game = CreateNewGame.new(
          user_id: current_user.id,
          player_name: new_game.player_name,
          question: new_game.question
        ).call
        game.save!
        redirect_to burn_unit_game_path(game.id)
      else
        render :new, locals: { new_game: }, status: :unprocessable_content
      end
    end

    def show
      game = Game.find(params[:id])
      current_player = game.player_for(current_user.id)

      if current_player.nil?
        redirect_to(new_burn_unit_game_player_path(game.id))
        return
      end

      case game.status
      when Game::Status.polling
        unless current_player.playing?
          current_player.playing = true
          current_player.save!
        end

        vote_form = VoteForm.new(game:, current_player:,
          candidate_id: current_player.vote)
        if current_player.judge?
          completed_round_form = CompletedRoundForm.new(game:)
          render :polling_judge,
            locals: { game:, current_player:, vote_form:,
                      completed_round_form: }
        else
          render :polling_player,
            locals: { game:, current_player:, vote_form: }
        end
      when Game::Status.completed
        render :completed, locals: { game:, current_player: }
      else
        raise "Unknown game status: #{game.status}"
      end
    end

    def new_round
      game = Game.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden if current_player.judge?

      new_round = NewRoundForm.new(game:)
      render :new_round, locals: { game:, current_player:, new_round: }
    end

    def create_round
      game = Game.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden if current_player.judge?

      new_round = NewRoundForm.new(
        game:,
        question: new_round_params[:question]
      )

      if new_round.valid?
        CreateNewRound.new(
          game:,
          judge: current_player,
          question: new_round.question
        ).call
        game.save!

        vote_form = VoteForm.new(game:, current_player:,
          candidate_id: current_player.vote)
        completed_round_form = CompletedRoundForm.new(game:)
        render :polling_judge,
          locals: { game:, current_player:, vote_form:, completed_round_form: }
      else
        render :new_round, locals: { game:, current_player:, new_round: },
          status: :unprocessable_content
      end
    end

    def completed_round
      game = Game.find(params[:id])
      current_player = game.player_for!(current_user.id)
      return head :forbidden unless current_player.judge?

      completed_round_form = CompletedRoundForm.new(game:)
      if completed_round_form.valid?
        CompleteRound.new(game:).call
        game.save!
        render :completed, locals: { game:, current_player: }
      else
        vote_form = VoteForm.new(game:, current_player:,
          candidate_id: current_player.vote)
        render :polling_judge,
          locals: { game:, current_player:, vote_form:,
                    completed_round_form: },
          status: :unprocessable_content
      end
    end

    private

    def new_game_params
      params.expect(game: %w[player_name question])
    end

    def new_round_params
      params.expect(round: %w[question])
    end
  end
end
