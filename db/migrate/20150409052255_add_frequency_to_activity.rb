class AddFrequencyToActivity < ActiveRecord::Migration
  def change
    add_column :answers, :frequency, :text
  end
end
