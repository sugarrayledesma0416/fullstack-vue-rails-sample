class DemoSubmissionRepartition
  MODEL_DEMO_STUDENT_USERNAMES = %w[model_demo_student_1 model_demo_student_2].freeze

  attr_accessor :year, :dry_run, :current_date, :partition_key

  def initialize(year:, dry_run: true)
    @year = year
    @dry_run = dry_run
    @current_date = Time.now.utc
    @partition_key = @current_date.strftime('%Y-%m-%d')
  end

  def model_student_attempts
    Attempt.where(user_id: demo_student_ids)
           .where('YEAR(attempts.created_at) = ?', @year)
           .where.not(submission_id: nil)
  end

  def update_attempt(attempt)
    ActiveRecord::Base.transaction do
      results_api = ResultsApiDatastore.new(attempt)
      original_result = results_api.read
      attempt.update!(created_at: @current_date) unless @dry_run
      results_api.write(original_result) unless @dry_run
      attempt
    end
  rescue StandardError => e
    Rails.logger.error("Transaction failed for attempt id #{attempt.id}: #{e.message}")
    nil
  end

  private def demo_student_ids
    @demo_student_ids ||= User.where(username: MODEL_DEMO_STUDENT_USERNAMES).pluck(:id)
  end
end
