class AddIdToPeople < ActiveRecord::Migration
  def change
    add_column :answers, :peopleId, :integer
  end
end
