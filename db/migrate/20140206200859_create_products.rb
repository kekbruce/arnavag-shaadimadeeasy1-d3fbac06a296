class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.column :vendor_id, :bigint, :null => false
      t.column :location_id, :bigint, :null => false
      t.column :category_id, :bigint, :null => false
      t.column :name, :string, :limit => 50, :null => false
      t.column :primary_image, :integer, :limit => 11, :null => false
      t.column :video_link, :string, :limit => 200, :null => true
      t.date :wedding_date, :string, :limit => 200, :null => true
      t.column :description, :text, :limit => 200, :null => true
      t.column :price_from, :integer, :limit => 11, :null => false
      t.column :price_to, :integer, :limit => 11, :null => false
      t.column :sh_recommendation_score, :integer, :limit => 11, :null => false
      t.column :user_recommendation_score, :integer, :limit => 11, :null => false
      t.timestamps :null => false
    end
  end
end
