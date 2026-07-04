# frozen_string_literal: true

# Rails interop identity (dom_id, routing, GlobalID) for aggregate wrappers
# that mirror an ActiveRecord model.
class GlobalIdentity
  def initialize(model:, id:)
    @model = model
    @id = id
  end

  def model_name = model.model_name
  def to_key = [id]
  def to_param = id

  def to_global_id(options = {})
    GlobalID.new(URI::GID.build(
      app: options.fetch(:app) { GlobalID.app },
      model_name: model.name,
      model_id: id,
      params: options.except(:app, :verifier, :for)
    ))
  end

  def to_gid_param(options = {}) = to_global_id(options).to_param

  private

  # @dynamic model, id
  attr_reader :model, :id
end
