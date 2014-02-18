class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.column :name, :string, :limit => 50, :null => false
      t.timestamps :null => false
    end
  end
end
