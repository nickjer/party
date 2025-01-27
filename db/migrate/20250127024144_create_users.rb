class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.timestamp :last_seen_at, null: false

      t.timestamps
    end
  end
end
