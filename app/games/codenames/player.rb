# frozen_string_literal: true

module Codenames
  # Aggregate for a Codenames player. Persistence goes through GameRepo
  # (via the parent game). Identity methods delegate to GlobalIdentity.
  class Player
    class << self
      def build(game_id:, user_id:, name:, team: nil, spymaster: false, id: nil)
        id ||= GameStore.generate_player_id
        document = Document.new(team:, spymaster:)
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

    def operative? = !team.nil? && !spymaster?

    def spymaster? = document.spymaster

    def spymaster=(is_spymaster)
      @document = document.with(spymaster: is_spymaster)
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
