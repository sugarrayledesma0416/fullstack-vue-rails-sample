class GracePeriodAllocation
  attr_accessor :school_id

  def initialize(school_id)
    self.school_id = school_id
  end

  def allowed?
    allowed > 0
  end

  def allowed
    grace_period_allocation['number_allowed']
  end

  def used
    grace_period_allocation['number_used']
  end

  def remaining
    grace_period_allocation['number_allowed'] - grace_period_allocation['number_used']
  end

  def duration
    grace_period_allocation['duration']
  end

  def grace_period_allocation
    school_guid = School.find_guid(school_id)
    @grace_period_allocation ||= Maestro::School.grace_period_allocation(school_guid)
  end
end
