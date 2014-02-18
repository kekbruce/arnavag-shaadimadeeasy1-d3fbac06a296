class CreateUserDetails < ActiveRecord::Migration
  def change
    create_table :user_details do |t|
      t.column :user_id, :bigint, :null => false
      t.column :mobile, :string, :limit => 10, :null => false
      t.column :city, :string,:limit => 20, :null => true
      t.timestamps :null => false
    end
  end
end
