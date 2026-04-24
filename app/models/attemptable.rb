module Attemptable
  def classwork_for(user, section)
    Classwork.new(user, section.id)
  end

  def attempt_for(user, section)
    @attempt_for ||= Attempt.find_or_new(user, self, section.id)
  end

  def attempt_track_for(user, section)
    attempt_for(user, section).attempt_track
  end
end