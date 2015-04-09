class AddMissingColumns < ActiveRecord::Migration
  def change
    add_column :answers, :cost_car, :float
    add_column :answers, :cost_transit, :float
    add_column :answers, :cost_bikesharing_member, :float
    add_column :answers, :cost_bikesharing_non_member, :float
    add_column :answers, :GHG_car, :float
    add_column :answers, :GHG_transit, :float
    add_column :answers, :GHG_bikesharing, :float
    add_column :answers, :cal_car, :float
    add_column :answers, :cal_bike, :float
    add_column :answers, :cal_transit, :float
    add_column :answers, :cal_walk, :float
    add_column :answers, :cal_bikesharing, :float
  end
end
