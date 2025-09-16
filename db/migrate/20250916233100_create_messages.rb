class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :conversation, null: false, foreign_key: true
      t.references :regarding, polymorphic: true, null: true

      t.text :content, null: false
      t.integer :status, default: 0, null: false
      t.integer :message_type, default: 0, null: false
      t.datetime :read_at
      t.json :metadata

      t.timestamps
    end

    add_index :messages, :status
    add_index :messages, :message_type
    add_index :messages, [:sender_id, :recipient_id]
    add_index :messages, [:conversation_id, :created_at]
    add_index :messages, :created_at
  end
end
