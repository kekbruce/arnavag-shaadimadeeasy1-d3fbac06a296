class CreateWeddingSites < ActiveRecord::Migration
  def change
    create_table :wedding_sites do |t|
      t.column :user_id, :bigint, :null => false, :default => 0
      t.column :page1, :string, :limit => 200, :null => false
      t.column :page2, :string, :limit => 200, :null => false
      t.column :page3, :string, :limit => 200, :null => false
      t.timestamps :null => false
    end
  end
end
