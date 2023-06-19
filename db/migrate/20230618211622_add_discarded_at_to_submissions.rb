class AddDiscardedAtToSubmissions < ActiveRecord::Migration[7.0]
  def change
    add_column :submissions, :discarded_at, :datetime
    add_index :submissions, :discarded_at
  end
end
