class Answer < ActiveRecord::Base
  def self.nextPeopleId
    begin
      max = maximum('peopleId') + 1
    rescue
      return 0
    else
      return max
    end
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << column_names
      all.each do |answer|
        csv << answer.attributes.values
      end
    end
  end
  end
