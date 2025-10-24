class CreateQualityScans < ActiveRecord::Migration[8.0]
  def change
    create_table :quality_scans do |t|
      t.references :app, null: false, foreign_key: true
      t.string :scan_type, null: false
      t.string :severity
      t.text :message
      t.string :file_path
      t.integer :line_number
      t.float :metric_value
      t.datetime :scanned_at

      t.timestamps
    end

    add_index :quality_scans, [:app_id, :scan_type]
    add_index :quality_scans, :severity
    add_index :quality_scans, :scanned_at
  end
end
