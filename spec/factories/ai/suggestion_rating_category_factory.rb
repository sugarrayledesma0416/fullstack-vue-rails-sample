FactoryBot.define do
  factory(:ai_suggestion_rating_category, class: 'AI::SuggestionRatingCategory') do |f|
    f.label { 'correct' }
    f.internal_use { false }
  end

  factory :ai_internal_suggestion_rating_category, parent: :ai_suggestion_rating_category do |f|
    f.internal_use { true }
  end
end
