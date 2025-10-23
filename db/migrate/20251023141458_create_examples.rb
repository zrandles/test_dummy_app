class CreateExamples < ActiveRecord::Migration[8.0]
  def change
    create_table :examples do |t|
      t.string :name
      t.string :category
      t.string :status
      t.text :description
      t.integer :priority
      t.decimal :score
      t.integer :complexity
      t.integer :speed
      t.integer :quality

      t.timestamps
    end
  end
end
