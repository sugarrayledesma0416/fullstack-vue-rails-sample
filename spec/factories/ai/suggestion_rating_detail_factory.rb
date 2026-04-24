FactoryBot.define do
  factory(:ai_suggestion_rating_detail, class: 'AI::SuggestionRatingDetail') do |f|
    f.association :attempt
    f.association :updated_by, factory: :user
    f.question_label { 'question_01' }
    f.comment { 'some general comment about some grading suggestions' }
  end
end
