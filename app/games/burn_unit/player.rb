# frozen_string_literal: true

module BurnUnit
  # Aggregate for a Burn Unit player. Persistence goes through GameRepo
  # (via the parent game). Identity methods delegate to GlobalIdentity.
  class Player
    class << self
      def build(game_id:, user_id:, name:, judge: false, playing: false,
        id: nil)
        id ||= GameStore.generate_player_id
        document = Document.new(
          judge: judge, score: 0, vote: nil, playing: playing
        )
        new(id:, game_id:, user_id:, name:, document:)
      end
    end

    # @dynamic id, game_id, user_id
    attr_reader :id, :game_id, :user_id

    def initialize(id:, game_id:, user_id:, name:, document:)
      @id = id
      @identity = GlobalIdentity.new(model: ::Player, id:)
      @game_id = game_id
      @user_id = user_id
      @name = name
      @document = document
    end

    def <=>(other) = name <=> other.name

    def ==(other) = self.class == other.class && id == other.id

    def eql?(other) = self == other

    def hash = id.hash

    def judge? = document.judge

    def judge=(is_judge)
      @document = document.with(judge: is_judge)
    end

    # @dynamic name, name=
    attr_accessor :name

    def online? = PlayerConnections.instance.count(id).positive?

    def playing? = document.playing

    def playing=(is_playing)
      @document = document.with(playing: is_playing)
    end

    def score = document.score

    def score=(new_score)
      @document = document.with(score: new_score)
    end

    def vote = document.vote

    def vote=(player_id)
      @document = document.with(vote: player_id)
    end

    def voted? = vote.present?

    def document_json = document.to_json

    def model_name = identity.model_name
    def to_key = identity.to_key
    def to_param = identity.to_param
    def to_global_id(options = {}) = identity.to_global_id(options)
    def to_gid_param(options = {}) = identity.to_gid_param(options)

    private

    # @dynamic document, identity
    attr_reader :document, :identity
  end
end
