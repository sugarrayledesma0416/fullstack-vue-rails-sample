FactoryBot.define do
  factory :vocab_word do
    base_word { 'bar' }
    language { 'es' }
    lesson
    target_definition { 'baz' }
    target_word { 'foo' }
    student
  end
end
