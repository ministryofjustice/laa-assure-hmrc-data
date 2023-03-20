class AddOmniAuthColumnsToUsers < ActiveRecord::Migration[7.0]
  def change
    change_table :users, bulk: true do |t|
      t.string :provider, null: false
      t.string :auth_subject_id
      t.timestamp :auth_last_sign_in_at
    end

    add_index :users, [:auth_subject_id, :provider], unique: true
  end
end
