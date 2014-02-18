class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.column :city, :string, :limit => 20, :null => false
      t.column :permalink, :string,:limit => 25 , :null => false
      t.timestamps :null => false
    end
  end
end
