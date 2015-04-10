class ChangeChoseModeColumnName < ActiveRecord::Migration
  def change
    rename_column :answers, :chose_mode_back, :chosen_mode_back
  end
end
