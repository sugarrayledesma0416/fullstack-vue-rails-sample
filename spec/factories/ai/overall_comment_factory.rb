FactoryBot.define do
  factory(:ai_overall_comment, class: 'AI::OverallComment') do |f|
    f.association :prompt, factory: :ai_overall_comment_prompt
    f.association :activity
    f.association :attempt
    f.association :program
    f.question_label { 'question_01' }
    f.overall_comment { 'Excellent work' }
    f.explanation { 'You followed directions well.' }
  end

  factory(:ai_internal_overall_comment, class: 'AI::OverallComment') do |f|
    f.association :prompt, factory: :ai_overall_comment_prompt
    f.association :grading_suggestion_input, factory: :ai_grading_suggestion_input
    f.question_label { 'question_01' }
    f.overall_comment { 'Excellent work' }
    f.explanation { 'You followed directions well.' }
  end
end
