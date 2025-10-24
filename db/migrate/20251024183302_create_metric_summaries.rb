class CreateMetricSummaries < ActiveRecord::Migration[8.0]
  def change
    create_table :metric_summaries do |t|
      t.references :app, null: false, foreign_key: true
      t.string :scan_type, null: false
      t.integer :total_issues, default: 0
      t.integer :high_severity, default: 0
      t.integer :medium_severity, default: 0
      t.integer :low_severity, default: 0
      t.float :average_score
      t.datetime :scanned_at
      t.text :metadata

      t.timestamps
    end

    add_index :metric_summaries, [:app_id, :scan_type]
    add_index :metric_summaries, :scanned_at
  end
end
