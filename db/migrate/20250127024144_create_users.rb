# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :string do |t|
      t.timestamp :last_seen_at, null: false

      t.timestamps
    end
  end
end
