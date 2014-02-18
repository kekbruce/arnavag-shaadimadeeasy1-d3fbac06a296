class CreateRecommendations < ActiveRecord::Migration
  def change
    create_table :recommendations do |t|
      t.column :product_id, :bigint, :null => false, :default => 0
      t.column :total_points, :integer, :limit => 11, :null => false,  :default => 0
      t.column :sh_points, :integer, :limit => 11, :null => false,  :default => 0
      t.column :user_points, :integer, :limit => 11, :null => false,  :default => 0
      t.timestamps :null => false
    end
  end
end
