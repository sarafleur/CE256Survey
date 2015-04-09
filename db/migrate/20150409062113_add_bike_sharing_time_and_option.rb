class AddBikeSharingTimeAndOption < ActiveRecord::Migration
  def change
    add_column :answers, :time_bikesharing_total, :float
    add_column :answers, :time_bikesharing_walking, :float
    add_column :answers, :bikesharing_option, :string
  end
end
