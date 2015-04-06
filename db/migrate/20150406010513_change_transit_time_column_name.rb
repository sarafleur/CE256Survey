class ChangeTransitTimeColumnName < ActiveRecord::Migration
  def change
    rename_column :answers, :time_transit_train, :time_transit_total
  end
end
