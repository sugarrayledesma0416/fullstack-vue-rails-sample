module CommonGradingViewLogic
  delegate :activity_partner_chat?, :activity_auto_graded?,
           :activity_solo_video_recording_or_included_in_multipart_activity?,
           :activity_solo_video_recording?, :activity_virtual_chat?, :response_id,
           :activity_recording_v2?, :feedback, :recording_path,
           :new_recording?, :activity, :activity_true_false_enhanced?,
           :activity_group_chat?, :activity_video_virtual_chat?,
           :activity_ai_virtual_chat?,
           :grading_status, :results, to: :presenter

  def arc_activity?
    activity_recording_v2?
  end

  def is_virtual_chat_type?
    activity_virtual_chat? || activity_video_virtual_chat?
  end

  def virtual_chat_partial
    if activity_video_virtual_chat?
      'video_virtual_chat'
    else
      'virtual_chat'
    end
  end

  def current_response_id(question)
    response_id(current_student, question)
  end
end
