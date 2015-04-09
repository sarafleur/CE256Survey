module AnswersHelper

  def question_title(activity)
    case activity
    when 'lunch'
      'Where do you go for lunch?'
    when 'leisure'
      'Where do you do your leisures?'
    when 'week-end'
      'Where do you go for week ends?'
    end
  end
end
