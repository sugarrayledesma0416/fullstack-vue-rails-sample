class PreviewAttempt
  attr_accessor :activity, :section, :user

  def initialize(activity:, section:, user:)
    @activity = activity
    @section = section
    @user = user
  end

  def id
    0
  end

  def complete?
    false
  end

  def practice?
    false
  end

  def smartbook_responses_with_feedback
    nil
  end

  def attempt_track
    @attempt_track ||= AttemptTrack.new(0, @activity.max_attempts || -1)
  end

  def effective_scoring_ruleset
    ScoringRuleset.default
  end

  def has_submittable_activity?
    @activity.gradable?
  end

  # for the activity header
  def updated_at
    Time.zone.now
  end

  def find_or_create_ai_virtual_chat_session
    AI::ConversationSession.create_preview(activity, user)
  end
end
