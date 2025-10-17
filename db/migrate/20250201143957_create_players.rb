# frozen_string_literal: true

class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.references :game, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.json :document, default: {}, null: false

      t.timestamps

      t.index %i[user_id game_id], unique: true
      t.index %i[name game_id], unique: true
    end
  end
end
