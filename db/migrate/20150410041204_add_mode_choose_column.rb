class AddModeChooseColumn < ActiveRecord::Migration
  def change
    add_column :answers, :current_mode, :text
    add_column :answers, :chosen_mode, :text
    add_column :answers, :chose_mode_back, :text
  end
end
