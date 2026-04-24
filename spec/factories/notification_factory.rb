FactoryBot.define do
  factory :notification do
    dismissed { false }
    user
    section
    created_at { Date.today }
  end

  factory :activity_graded_notification, parent: :notification, class: ActivityGradedNotification do
    dismissed { false }
    activity
  end

  factory :activity_feedback_notification, parent: :notification, class: ActivityFeedbackNotification do
    dismissed { false }
    activity
  end

  factory :changed_earned_score_notification, parent: :notification, class: ChangedEarnedScoreNotification do
    dismissed { false }
    activity
  end

  factory :activity_late_penalty_for_score_notification, parent: :notification, class: ActivityLatePenaltyForScoreNotification do
    dismissed { false }
    activity
  end

  factory :announcement_posted_notification, parent: :notification, class: AnnouncementPostedNotification do
    dismissed { false }
  end

  factory :late_work_accepted_notification, parent: :notification, class: LateWorkAcceptedNotification do
    dismissed { false }
    activity
  end

  factory :help_request_response_notification, parent: :notification, class: HelpRequestResponseNotification do
    dismissed { false }
    activity
  end
end
