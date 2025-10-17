# frozen_string_literal: true

class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.integer :kind, null: false
      t.string :slug, null: false
      t.json :document, default: {}, null: false

      t.timestamps
    end
    add_index :games, :slug, unique: true
  end
end
