class CreateConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.references :participant1, null: false, foreign_key: { to_table: :users }
      t.references :participant2, null: false, foreign_key: { to_table: :users }
      t.datetime :last_message_at
      t.boolean :archived, default: false
      t.datetime :archived_at

      t.timestamps
    end

    add_index :conversations, [:participant1_id, :participant2_id], unique: true
    add_index :conversations, :last_message_at
    add_index :conversations, :archived
  end
end
