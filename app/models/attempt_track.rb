class AttemptTrack
  attr_accessor :max

  def initialize(attempt_number, max)
    @attempt_number = attempt_number
    @max = max
  end

  def used
    number - 1
  end

  def number
    @attempt_number + 1
  end

  def attempt_number=(val)
    @attempt_number = val
  end

  def remaining
    unlimited? ? 'unlimited' :  (max.to_i - used).to_s
  end

  def final?
    !unlimited? && number >= max.to_i
  end

  def complete?
    @complete
  end

  def complete=(complete)
    @complete = complete
  end

  def practice?
    @practice
  end

  def practice=(practice)
    @practice = practice
  end

  def view_only?
    !unlimited? && max.to_i == 0
  end

  def submitted?
    used > 0
  end

  def unlimited?
    max == -1
  end
  private :unlimited?
end
