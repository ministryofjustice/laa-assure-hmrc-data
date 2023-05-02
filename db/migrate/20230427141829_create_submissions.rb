class CreateSubmissions < ActiveRecord::Migration[7.0]
  # JSON versus JSONB, and `GIN` (Generalized Inverted Index) indexes
  # https://www.dbvis.com/thetable/json-vs-jsonb-in-postgresql-a-complete-comparison/
  # https://nandovieira.com/using-postgresql-and-jsonb-with-ruby-on-rails

  def change
    create_table :submissions, id: :uuid do |t|
      t.references :bulk_submission, type: :uuid, foreign_key: true, index: true

      t.datetime :period_start_at
      t.datetime :period_end_at
      t.string :use_case, null: false
      t.string :first_name, null: false, default: ""
      t.string :last_name, null: false, default: ""
      t.datetime :dob
      t.string :nino, null: false, default: ""
      t.string :status, null: false, default: ""
      t.uuid :hmrc_interface_id
      t.jsonb :hmrc_interface_result, null: false, default: '{}'

      t.timestamps null: false
    end

    add_index :submissions, :hmrc_interface_id, unique: true
    add_index :submissions, :hmrc_interface_result, using: :gin
  end
end

