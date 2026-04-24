class PartnerChatPartnerSubmission
  attr_reader :activity

  def initialize(partner_id, partner_section_id, activity)
    @partner_id = partner_id
    @partner_section_id = partner_section_id
    @activity = activity
  end

  def submission_required?
    # partner_attempt will be nil if the partner is an instructor,
    #   but we will not use it in that case since we won't get to the second
    #   predicate.
    # Disable auto submission for info_gap_partner_chat_v2 to allow each student
    # to complete their activities independently
    return false if activity.activity_type == 'info_gap_partner_chat_v2'

    !partner.instructor? && !partner_attempt.completed?
  end

  def submit(params, label, recording, activity_complete, time_now_in_seconds)
    return unless submission_required?

    partner_results = partner_attempt.validate_responses(activity, params, {})
    partner_results.set_response(label, recording.id.to_s)
    partner_attempt.write_results(
      partner_results,
      activity_complete,
      'submitted',
      params[:start_time].to_i,
      time_now_in_seconds
    )
    partner_submission = Gradebook::Submission.new(partner, partner_section, activity)
    partner_submission.submit(
      partner_results,
      Time.now.utc,
      partner_attempt.time_spent,
      partner_attempt.submission_length(partner_results)
    )
  end

  private def partner
    @partner ||= User.find(@partner_id)
  end

  private def partner_section
    @partner_section ||= Section.find(@partner_section_id)
  end

  private def partner_attempt
    return @partner_attempt if defined?(@partner_attempt)
    @partner_attempt = Attempt.where(
      activity_id: activity,
      section_id: partner_section,
      user_id: partner
    ).first
  end
end
