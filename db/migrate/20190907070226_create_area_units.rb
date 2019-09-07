class CreateAreaUnits < ActiveRecord::Migration[6.0]
  def change
    create_table :area_units do |t|
      t.text :name
      t.geometry :shape, geographic: true
      t.timestamps
    end
  end
end
