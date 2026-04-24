class GroupChatSubmission < BaseVideoSubmission
  # Fetch results to create a group chat recording record then
  # replace the results with the record's id

  def prepare_for_submission(activity_complete, time_now_in_seconds)
    results.set_response(label, recording.id.to_s)
    # On initial submission, there is only an id in the results
    # When we render the complete view, we expect to have a video path, not an id
    response[:partner_ids].each do |partner_id|
      p_submission = partner_submission(partner_id)
      p_submission.submit(params, label, recording, activity_complete, time_now_in_seconds)
    end
  end

  def recording
    return @recording if defined? @recording
    recording = GroupChatRecording.new(user_id: response[:user_id],
                                       participants: response[:partner_ids],
                                       recording_path: response[:recording_path],
                                       token: response[:token],
                                       activity: activity)
    response[:partner_ids].each do |partner_id|
      if partner_attempt_completed?(partner_id)
        recording.practicing_users.push(partner_id)
      end
    end
    @recording = recording if recording.save!
    @recording
  end

  def partner_submission(partner_id)
    (@partner_submission ||= {})[partner_id] ||= GroupChatPartnerSubmission.new(partner_id,
                                                                                response[:partner_section_ids][partner_id],
                                                                                activity)
  end

  private def partner_attempt_completed?(partner_id)
    Attempt.where(
      activity_id: activity,
      section_id: response[:partner_section_ids][partner_id],
      user_id: partner_id
    ).first.completed?
  end
end
