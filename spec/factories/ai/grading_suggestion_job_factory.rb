FactoryBot.define do
  factory(:ai_grading_suggestion_job, class: 'AI::GradingSuggestionJob') do |f|
    f.association :attempt
    f.question_label { 'question_01' }
    f.status { 'in_progress' }
  end
end
