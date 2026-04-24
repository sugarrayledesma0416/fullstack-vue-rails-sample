module AttemptViewDecorator
  def in_completed_view_without_results?
    current_view == :complete && !results ? true : false
  end

  def assign_practice_complete(commit, results_completed)
    if commit == 'Answers' || results_completed
      self.practice_complete = true
      self.status_code = AttemptStatus::CODE_COMPLETED
      self.updated_at = Time.now.utc
    else
      self.practice_complete = false
    end
  end

  def assign_view_and_notice(commit)
    if user.instructor?
      [:show]
    elsif practice_complete?
      [:complete, 'Viewing answers.']
    elsif commit == 'Check'
      [:submit, 'Practice mode. Answers will not be saved!']
    else
      [:show, 'Practice mode. Answers will not be saved!']
    end
  end
end
