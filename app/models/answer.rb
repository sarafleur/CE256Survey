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
end
