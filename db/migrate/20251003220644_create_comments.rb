class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.text :content, null: false
      t.string :author_name
      t.string :author_email
      t.references :blog_post, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :comments }
      t.string :status, default: 'pending'
      t.datetime :approved_at
      t.references :user, foreign_key: true

      t.timestamps
    end

    add_index :comments, :status
    add_index :comments, :approved_at
    add_index :comments, [ :blog_post_id, :status ]
  end
end
