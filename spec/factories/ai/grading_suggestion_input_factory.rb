FactoryBot.define do
  factory(:ai_grading_suggestion_input, class: 'AI::GradingSuggestionInput') do |f|
    f.association :program
    f.association :attempt
    activity do |proxy|
      proxy.attempt.activity
    end
    question_label { 'question_01' }
    f.student_response { 'something' }
  end
end
