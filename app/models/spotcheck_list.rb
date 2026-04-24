class SpotcheckList < GradingStudentListBase
  def manual_student_list
    @manual_student_list ||= filtered_students.select do |student|
      score = scores[student.id]
      score&.seconds_spent.to_i.positive?
    end
  end

  # Even though we're sorting after randomizing, the shuffle will still
  # ensure random order when spotcheck_count is tied.
  def random_student_list
    manual_student_list.shuffle.sort_by(&:spotcheck_count)
  end

  def outlier_student_list
    scores.each_value do |score|
      score.time_spent_deviation = (score.seconds_spent.to_i - average_time_spent).abs
    end
    # Specified as b <=> a so that greatest values come first.
    manual_student_list.sort { |a, b| score_for(b) <=> score_for(a) }
  end

  def score_for(student)
    scores[student.id]
  end

  def grade_for(student)
    top_level_grades[student.id]&.net_ratio
  end

  def time_spent_for(student)
    scores[student.id]&.seconds_spent.to_i
  end

  def submission_length_for(student)
    attempts[student.id]&.submission_length
  end

  # The index_by(&:user_id) provides easy access to the scores for a user,
  # but in the rare case that the same user has scores for the same activity
  # in multiple sections in the same course, only the last score retrieved
  # will be displayed. This shouldn't be too much of a problem as students
  # cannot be active in multiple sections of the same course. Instructors
  # will generally only see scores from the section the student was enrolled
  # in when they submitted the work.
  # This limitation also applies to the top_level_grades and attempts methods.
  private def scores
    @scores ||= GradebookEngine::GradebookAPI.spotcheck_results(
      activity_id: activity_id,
      section_ids: section_ids,
      user_ids: student_ids
    ).map { |score| score.extend(TimeSpentDeviationComparable) }.index_by(&:user_id)
    @scores
  end

  private def top_level_grades
    @grades ||= GradebookEngine::GradebookAPI.top_level_grades(
      section_ids: section_ids
    ).index_by { |grade| grade.user.id }
  end

  private def attempts
    @attempts ||= Attempt.submitted_or_completed.where(
      activity_id: activity_id,
      section_id: section_ids,
      user_id: student_ids
    ).index_by(&:user_id)
  end

  private def student_ids
    @student_ids ||= students.map(&:id)
  end

  private def average_time_spent
    return @average_time_spent if defined?(@average_time_spent)

    total_time_spent = scores.values.sum { |score| score.seconds_spent.to_i }
    @average_time_spent = scores.empty? ? 0 : total_time_spent / scores.count
  end

  module TimeSpentDeviationComparable
    attr_accessor :time_spent_deviation

    def <=>(other)
      time_spent_deviation <=> other.time_spent_deviation
    end
  end
end
