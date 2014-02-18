class CreateWeddingPlans < ActiveRecord::Migration
  def change
    create_table :wedding_plans do |t|

      t.timestamps
    end
  end
end
