class RecordingSaver

  attr_accessor :activity, :user, :results

  def initialize(activity, user, results)
    self.activity = activity
    self.user = user
    self.results = results
  end

  def save_recordings
    create_for_vchat_activity if activity.virtual_chat?
    create_for_recording_activity if activity.recording_v2?
  end

  def create_for_recording_activity
    responses.each { |response| create_recording(response) }
  end
  private :create_for_recording_activity

  def create_for_vchat_activity
    turns.each { |turn| create_recording(turn) }
  end
  private :create_for_vchat_activity

  def create_recording(recording_path)
    Recording.create!(:user => user,
                     :recording_path => recording_path)
  end
  private :create_recording

  def responses
    responses = results.map { |result| result[:response] }

    # We need to filter those responses that exist in recordings already
    responses - saved_recording_paths(responses)
  end
  private :responses

  def turns
    turn_paths = activity.content_object.turn_paths(results)

    # We need to filter those responses that exist in recordings already
    turn_paths - saved_recording_paths(turn_paths)
  end

  def saved_recording_paths(recording_paths)
    Recording.where(:recording_path => recording_paths).pluck(:recording_path)
  end
end
