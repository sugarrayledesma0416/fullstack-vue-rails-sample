module MultipleDueDatesChecker
  def assigned_on_multiple_dates?(activity_assignments)
    (
      activity_assignments.count > 1 &&
      activity_assignments.map(&:due_date).uniq.count > 1

    ) || activity_assignments.any? do |assignment|
      assignment.respond_to?(:multiple_due_dates?) &&
        assignment.multiple_due_dates?
    end
  end
end
