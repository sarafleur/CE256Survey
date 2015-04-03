class CreateAnswers < ActiveRecord::Migration
  def change
    create_table :answers do |a|
        a.boolean :has_transit_pass
        a.boolean :has_car
        a.boolean :has_e_car
        a.boolean :has_bike
        a.boolean :has_e_bike
        a.float :lat_origin
        a.float :lat_destination
        a.float :lon_origin
        a.float :lon_destination
        a.string :activity #can be work or primary other activity
        a.float :time_car
        a.float :time_bike
        a.float :time_walk
        a.float :time_transit_train
        a.float :time_transit_walk
        a.float :price_transit_pass_proposed
        a.boolean :wants_transit_pass
        a.integer :age
        a.string :income
        a.timestamps null: false
    end
  end
end
