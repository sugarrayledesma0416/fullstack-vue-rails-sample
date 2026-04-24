class AttemptStatus
  CODE_UNOPENED  = nil
  CODE_OPENED    = 0
  CODE_SUBMITTED = 1
  CODE_COMPLETED = 2
  CODE_RESET     = 3
  CODE_STARTED   = 4 

  def initialize(attempt)
    @attempt = attempt
  end

  def status
    case status_code
    when nil              then :unopened
    when CODE_OPENED      then :opened
    when CODE_STARTED     then :started
    when CODE_SUBMITTED   then :submitted
    when CODE_COMPLETED   then :completed
    when CODE_RESET       then :reset
    end
  end

  def attempted?
    status_code != CODE_UNOPENED && status_code != CODE_OPENED && status_code != CODE_STARTED
  end

  def complete?
    if attempt.practice?
      attempt.practice_complete?
    else
      completed?
    end
  end

  def completed?
    status_code == CODE_COMPLETED
  end

  def submitted?
    status_code == CODE_SUBMITTED
  end

  def submitted_or_completed?
    submitted? || completed?
  end

  def unsubmitted?
    !submitted? && !complete?
  end

  def reset?
    status_code == CODE_RESET
  end

  def expanded_status
    if (status == :opened && attempt.saved_values?) || (status == :submitted)
      :incomplete
    else
      status
    end
  end

  def attempt
    @attempt
  end
  private :attempt

  def status_code
    attempt.status_code
  end
  private :status_code
end
