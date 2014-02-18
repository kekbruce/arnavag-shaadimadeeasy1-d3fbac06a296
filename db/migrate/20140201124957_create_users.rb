class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column :email, :string, :limit => 200, :null => false
      t.column :username, :string, :limit => 200, :null => false
      t.column :fb_user_id, :bigint, :null => false, :default => 0
      t.column :credit_amount, :float, :null => false,  :default => 0
      t.column :total_email_invites, :integer, :null => false, :default => 0
      t.column :city, :string, :limit => 200, :null => true
      t.column :region, :string, :limit => 200, :null => true
      t.timestamps :null => false
    end
    add_index :users, :email, :unique=>true, :name => "UNIQUE"
    add_index :users, :username, :unique=>true, :name => "UNIQUE1"
    add_index :users, :fb_user_id
  end

  def self.down
    drop_table :users
  end

end
