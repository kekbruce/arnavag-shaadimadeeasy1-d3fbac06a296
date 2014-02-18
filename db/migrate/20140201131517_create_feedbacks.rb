class CreateFeedbacks < ActiveRecord::Migration
  def self.up
    create_table :feedbacks do |t|
      t.text :body, :null => false
      t.column :username, :string, :limit => 30, :null => false
      t.column :type, :string, :limit => 20, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :feedbacks
  end

end
