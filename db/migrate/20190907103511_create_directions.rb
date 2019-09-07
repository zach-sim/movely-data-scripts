class CreateDirections < ActiveRecord::Migration[6.0]
  def change
    create_table :directions do |t|
      t.references :from_au
      t.references :to_au

      t.geometry :path
      t.json :data

      t.integer :type
      t.timestamps
    end
  end
end
