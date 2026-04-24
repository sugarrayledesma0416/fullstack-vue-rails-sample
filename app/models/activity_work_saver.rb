class ActivityWorkSaver
  attr_accessor :activity, :attempt
  attr_reader :results, :attempt_track


  def initialize(activity, attempt, params, request_env)
    self.activity = activity
    self.attempt = attempt
    @activity_params = params
    @request_env = request_env
  end

  def save
    attempt_results = attempt.validate_responses(activity,
                                                 @activity_params,
                                                 @request_env,
                                                 :unsubmitted)
    attempt.write_results(attempt_results,
                          false,
                          :unsubmitted,
                          @activity_params[:start_time].to_i,
                          Time.now.utc.to_i)
    @results = attempt.results
    @attempt_track = attempt.attempt_track
    RecordingSaver.new(activity, attempt.user, @results).save_recordings
    self
  end

end
