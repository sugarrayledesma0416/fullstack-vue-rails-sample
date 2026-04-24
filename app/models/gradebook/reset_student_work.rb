#########################
# New Gradebook Version #
# the gradebook engine performs the reset_score action before calling this
# this class handles reseting the attempt, help_requests and study_plan, if applicable
#########################

module Gradebook
  class ResetStudentWork
    # The new gradebook handles all external activities, so we're only
    # concerned with regular activities.
    def initialize(activity_id, section_id, user_id)
      @activity_id = activity_id
      @section_id = section_id
      @user_id = user_id
    end

    def activity
      @activity ||= Activity.find(@activity_id)
    end

    def section
      @section ||= Section.find(@section_id)
    end

    def user
      @user ||= User.find(@user_id)
    end

    def process
      clear_help_requests
      reset_attempt

      # If the activity is a study plan practice test or diagnostic_v2,
      # then its correlating study plan also needs to be reset.
      #  Other activity types do not have study plans.
      reset_study_plan if activity.has_study_plan?
    end

    private def clear_help_requests
      HelpRequest.where(
        user_id: @user_id,
        activity_id: @activity_id,
        section_id: @section_id
      ).destroy_all
    end

    private def reset_attempt
      Attempt.transaction do
        unless Attempt.where(user_id: user.id,
                             section_id: section.id,
                             activity_id: activity.id).blank?
          Attempt.reset_attempt(user, section, activity)
        end
      end
    end

    private def reset_study_plan
      UserReading.select('user_readings.*')
        .joins(recommendation: :study_plan_concept)
        .where(user_readings: { user_id: @user_id })
        .where(study_plan_concepts: { activity_id: @activity_id })
        .destroy_all
      activity.notifications
              .dispatch('StudyPlanReset', section: section, user: user)
    end
  end
end
