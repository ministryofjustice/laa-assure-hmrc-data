class CreateBulkSubmissions < ActiveRecord::Migration[7.0]
  def change
    create_table :bulk_submissions, id: :uuid do |t|
      t.references :user, type: :uuid, foreign_key: true, index: true
      t.datetime   :expires_at, null: true
      t.string     :status
      t.timestamps null: false
    end
  end
end
