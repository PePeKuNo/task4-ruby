class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :full_name, null: false
      t.string :email, null: false
      t.string :job_position, null: false
      t.datetime :last_seen, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.string :status, null: false, default: 'active'
      t.string :password_digest, null: false

      t.timestamps
    end

    # IMPORTANT: Unique index on email at DATABASE level (not just validation).
    # This guarantees email uniqueness independently of how many sources push data simultaneously.
    # NOTA BENE: This is a UNIQUE INDEX, not a primary key. Primary key is 'id' (auto-created).
    add_index :users, :email, unique: true, name: 'index_users_on_email_unique'

    # NOTE: Index on status for faster filtering of active/blocked users
    add_index :users, :status, name: 'index_users_on_status'

    # NOTE: Index on last_seen for sorting (requirement: data sorted by last login time)
    add_index :users, :last_seen, name: 'index_users_on_last_seen'
  end
end