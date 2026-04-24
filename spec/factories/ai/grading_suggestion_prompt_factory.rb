FactoryBot.define do
  factory(:ai_grading_suggestion_prompt, class: 'AI::GradingSuggestionPrompt') do |f|
    f.active_for_instructor_grading { false }
    f.model { 'fake_model' }
    f.temperature { 0.5 }
    f.template_body { 'fake_body' }
  end
end
