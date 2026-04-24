FactoryBot.define do
  factory(:ai_grading_suggestion_rating, class: 'AI::GradingSuggestionRating') do |f|
    f.association :grading_suggestion, factory: :ai_grading_suggestion
    f.association :user
    f.association :rating_category, factory: :ai_suggestion_rating_category
  end
end
