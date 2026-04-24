FactoryBot.define do
  factory(:ai_grading_suggestion, class: 'AI::GradingSuggestion') do |f|
    f.association :prompt, factory: :ai_grading_suggestion_prompt
    f.association :activity
    f.association :attempt
    f.association :program
    f.question_label { 'question_01' }
    f.incorrect_text { 'foo bam' }
    f.error_explanation { 'You misspelled a word.' }
  end

  factory(:ai_internal_grading_suggestion, class: 'AI::GradingSuggestion') do |f|
    f.association :prompt, factory: :ai_grading_suggestion_prompt
    f.association :grading_suggestion_input, factory: :ai_grading_suggestion_input
    f.question_label { 'question_01' }
    f.incorrect_text { 'foo bam' }
    f.error_explanation { 'You misspelled a word.' }
  end
end
