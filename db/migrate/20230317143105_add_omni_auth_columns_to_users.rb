class AddOmniAuthColumnsToUsers < ActiveRecord::Migration[7.0]
  def change
    change_table :users, bulk: true do |t|

      # Omniauthable, custom devise
      t.string :auth_provider, null: false, default: ""
      t.string :auth_subject_uid

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip
    end

    add_index :users, [:auth_subject_uid, :auth_provider], unique: true
  end
end
