FactoryBot.define do
  factory(:ai_overall_comment_rating, class: 'AI::OverallCommentRating') do |f|
    f.association :overall_comment, factory: :ai_overall_comment
    f.association :user
    f.association :rating_category, factory: :ai_suggestion_rating_category
  end
end
