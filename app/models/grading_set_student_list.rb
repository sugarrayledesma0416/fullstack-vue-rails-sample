class GradingSetStudentList < GradingStudentListBase
  def user_ids
    # Uses array intersection to find all scores that have attempts with the
    # same user id and section id, return the user_ids (the first element
    # in the 2-tuple).
    (scores & attempts).map(&:first)
  end

  private def scores
    GradebookEngine::GradebookAPI.find_submitted(query_args).map do |score|
      [score.user_id, score.section_id]
    end
  end

  private def attempts
    Attempt.select('user_id, section_id')
           .submitted_or_completed
           .where(query_args)
           .map { |attempt| [attempt.user_id, attempt.section_id] }
  end

  private def query_args
    {
      activity_id: activity_id,
      section_id: section_ids,
      user_id: filtered_students
    }
  end
end
