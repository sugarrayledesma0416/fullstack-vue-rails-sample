FactoryBot.define do
  factory :rubric_criteria_score do
    criteria_score_json { "{\"Content\"=>\"4\", \"Organization\"=>\"3\", \"Accuracy\"=>\"3\"}" }
    association :attempt, factory: :attempt
  end
end
