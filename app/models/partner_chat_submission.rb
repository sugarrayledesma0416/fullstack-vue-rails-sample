class PartnerChatSubmission < BaseVideoSubmission
  # Fetch results to create a partner chat recording record then replace the results with the record's id

  def prepare_for_submission(activity_complete, time_now_in_seconds)
    results.set_response(label, recording.id.to_s)
    # On initial submission, there is only an id in the results
    # When we render the complete view, we expect to have a video path, not an id
    partner_submission.submit(params, label, recording, activity_complete, time_now_in_seconds)
  end

  def recording
    return @recording if defined? @recording

    recording = PartnerChatRecording.new(user_id: response[:user_id],
                                         partner_id: response[:partner_id],
                                         recording_path: response[:recording_path],
                                         token: response[:token],
                                         activity: activity)
    recording.partner_practice = true unless partner_submission.submission_required?
    @recording = recording if recording.save!

    @recording
  end

  def partner_submission
    @partner_submission ||= PartnerChatPartnerSubmission.new(response[:partner_id],
                                                             response[:partner_section_id],
                                                             activity)
  end
end
