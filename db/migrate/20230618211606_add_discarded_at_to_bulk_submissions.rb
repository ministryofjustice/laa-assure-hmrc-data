class AddDiscardedAtToBulkSubmissions < ActiveRecord::Migration[7.0]
  def change
    add_column :bulk_submissions, :discarded_at, :datetime
    add_index :bulk_submissions, :discarded_at
  end
end
