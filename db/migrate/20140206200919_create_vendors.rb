class CreateVendors < ActiveRecord::Migration
  def change
    create_table :vendors do |t|
      t.column :user_id, :bigint, :null => false, :default => 0
      t.column :vendor_gallery, :string, :limit => 100
      t.column :vendor_page, :string, :limit => 100
      t.timestamps :null => false
    end
  end
end
