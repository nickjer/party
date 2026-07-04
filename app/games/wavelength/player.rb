# frozen_string_literal: true

module Wavelength
  # Aggregate for a Wavelength player. Persistence goes through GameRepo
  # (via the parent game). Identity methods delegate to GlobalIdentity.
  class Player
    class << self
      def build(game_id:, user_id:, name:, team: nil, id: nil)
        id ||= GameStore.generate_player_id
        document = Document.new(team:, psychic_count: 0)
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

    # Order by team (red, then blue, then unassigned), then by name.
    def <=>(other)
      return team_rank <=> other.team_rank if team_rank != other.team_rank

      name <=> other.name
    end

    def ==(other) = self.class == other.class && id == other.id

    def eql?(other) = self == other

    def hash = id.hash

    # @dynamic name, name=
    attr_accessor :name

    def online? = PlayerConnections.instance.count(id).positive?

    def psychic_count = document.psychic_count

    def increment_psychic_count
      @document = document.with(psychic_count: psychic_count + 1)
    end

    def team = document.team

    def team=(new_team)
      @document = document.with(team: new_team)
    end

    def document_json = document.to_json

    def model_name = identity.model_name
    def to_key = identity.to_key
    def to_param = identity.to_param
    def to_global_id(options = {}) = identity.to_global_id(options)
    def to_gid_param(options = {}) = identity.to_gid_param(options)

    protected

    def team_rank
      if team&.red? then 0
      elsif team&.blue? then 1
      else 2
      end
    end

    private

    # @dynamic document, identity
    attr_reader :document, :identity
  end
end
