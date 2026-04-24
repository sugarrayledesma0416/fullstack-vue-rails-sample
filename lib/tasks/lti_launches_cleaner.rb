class LtiLaunchesCleaner
  attr_accessor :batch_size, :date

  def initialize(batch_size:, date: 30.days.ago.to_date.to_s)
    self.batch_size = batch_size
    self.date = date
  end

  def num_batches
    (launches_to_clean.count + batch_size - 1) / batch_size
  end

  def clean
    launches_to_clean.in_batches(of: batch_size) do |batch|
      batch.delete_all
      yield if block_given?
    end
  end

  private def launches_to_clean
    # uses AREL to generate date comparison SQL rather than string interpolation
    Lti::Launch.where(Lti::Launch.created_at_column.lteq(date))
  end
end
