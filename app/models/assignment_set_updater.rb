class AssignmentSetUpdater
  attr_accessor :attrs, :id

  def initialize(id, attrs)
    self.id = id
    self.attrs = attrs
  end

  def update
    AssignmentSet.transaction do
      assignment_set.activities = attrs[:activities].map do |activity_entry|
        AssignmentSetActivity.new(activity_entry)
      end
    rescue ActiveRecord::RecordNotSaved
      report_failures
    end
    self
  end

  def errors
    assignment_set.errors.full_messages
  end

  def valid?
    assignment_set.errors.empty?
  end

  private def assignment_set
    @assignment_set ||= AssignmentSet.find(id)
  end

  private def report_failures
    assignment_set.errors.add(
      :activities,
      'could not be updated because one or more records failed validation'
    )
    raise ActiveRecord::Rollback
  end
end
