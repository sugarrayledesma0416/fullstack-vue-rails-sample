class BaseVideoSubmission
  attr_reader :results, :activity, :params

  def initialize(_results, _activity, _params)
    @results = _results
    @activity = _activity
    @params = _params
  end

  def response
    @response ||= results.response(label)
  end

  def label
    @label ||= results.first[:label]
  end

  def video_path
    @video_path ||= recording.recording_path
  end

  def prepare_for_submission(activity_complete, time_now_in_seconds)
    raise NotImplementedError
  end

  def recording
    raise NotImplementedError
  end
end
