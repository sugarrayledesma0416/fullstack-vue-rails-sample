FactoryBot.define do
  factory :user_reading do
    user
    recommendation
    viewed { false }
    concept_score { 80 }
  end
end
