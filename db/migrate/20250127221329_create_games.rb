# frozen_string_literal: true

class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games, id: :string do |t|
      t.integer :kind, null: false
      t.json :document, default: {}, null: false

      t.timestamps
    end
  end
end
