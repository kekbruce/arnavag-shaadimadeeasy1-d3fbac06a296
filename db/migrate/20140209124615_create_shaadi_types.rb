class CreateShaadiTypes < ActiveRecord::Migration
  def change
    create_table :shaadi_types do |t|
      t.column :name, :string, :limit => 30, :null => false
      t.timestamps :null => false
    end
  end
end
