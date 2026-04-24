FactoryBot.define do
  sequence(:cms_activity_id) { |n| 10 + n }

  factory :attempt do
    activity
    scoring_ruleset { ScoringRuleset.default }
    section
    cms_activity_id { activity&.cms_activity_id || generate(:cms_activity_id) }
    # Use the cms_revision_id of the activity if present or the sequence defined
    # in the activity factory file.
    cms_revision_id { activity&.cms_revision_id || generate(:cms_revision_id) }
    status_code { AttemptStatus::CODE_OPENED }
    time_spent { 0 }
    association :user, factory: :student
  end

  factory :attempt_opened, parent: :attempt do
    status_code { AttemptStatus::CODE_OPENED }
  end

  factory :attempt_submitted, parent: :attempt do
    status_code { AttemptStatus::CODE_SUBMITTED }
  end

  factory :attempt_completed, parent: :attempt do
    status_code { AttemptStatus::CODE_COMPLETED }
  end

  factory :attempt_reset, parent: :attempt do
    status_code { AttemptStatus::CODE_RESET }
  end
end
