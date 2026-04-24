FactoryBot.define do
  factory(:ai_overall_comment_prompt, class: 'AI::OverallCommentPrompt') do |f|
    f.active_for_instructor_grading { false }
    f.model { 'fake_model' }
    f.temperature { 0.5 }
    f.template_body { 'fake_body' }
  end
end
