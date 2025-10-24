class CreateApps < ActiveRecord::Migration[8.0]
  def change
    create_table :apps do |t|
      t.string :name, null: false
      t.string :path, null: false
      t.datetime :last_scanned_at
      t.string :status

      t.timestamps
    end

    add_index :apps, :name, unique: true
    add_index :apps, :last_scanned_at
    add_index :apps, :status
  end
end
