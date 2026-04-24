module AttemptTrackHelper

  def format_used_and_remaining(attempt_track)
    if attempt_track.nil?
      ''
    elsif attempt_track.practice?
      'Practice mode'
    elsif attempt_track.view_only?
      'Activity viewed'
    elsif attempt_track.complete?
      "#{attempt_track.used} used / Activity complete"
    else
      "#{attempt_track.used} used / #{attempt_track.remaining} remaining"
    end
  end

  def format_remaining(attempt)
    attempt_track = attempt.attempt_track
    if attempt_track.nil?
      ''
    elsif attempt_track.practice?
      'Practice mode'
    elsif attempt && !attempt.has_submittable_activity? 
      "Viewed on #{format_date_time(attempt.updated_at, :month_ordinal)}".html_safe
    elsif attempt_track.view_only? || attempt_track.complete?
      "Completed on #{format_date_time(attempt.updated_at, :month_ordinal_with_time)}".html_safe
    else
      "#{pluralize(attempt_track.remaining, 'attempt')} left"
    end
  end
end
