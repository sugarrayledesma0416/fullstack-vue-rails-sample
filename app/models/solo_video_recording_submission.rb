class SoloVideoRecordingSubmission < BaseVideoSubmission
  # Fetch results to create a solo video recording record
  # then replace the results with the record's id

  # have to get the label based on whether or not
  # the SVR is stand alone or in a multipart activity
  def label
    @label ||= if activity.activity_type == 'solo_video_recording'
                 results.first[:label]
               else
                 activity.content_object.solo_video_recording_subactivity.label
               end
  end


  def prepare_for_submission(activity_complete, time_now_in_seconds)
    results.set_response(label, recording.id.to_s)
  end

  def recording
    return @recording if @recording
    recording = SoloVideoRecording.new(:user_id => response[:user_id],
                                       :recording_path => response[:recording_path],
                                       :activity => activity)
    @recording = recording if recording.save!
    @recording
  end
end
