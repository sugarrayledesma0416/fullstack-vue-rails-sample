class ActivityResponseBuilder
  attr_reader :video_path, :activity

  def initialize(activity, video_path)
    @activity = activity
    @video_path = video_path
  end

  def response
    {
      :video_path => video_path
    }
  end

  def to_json
    response.to_json 
  end

  def status
    :ok
  end

end
