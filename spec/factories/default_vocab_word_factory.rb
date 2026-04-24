FactoryBot.define do
  factory :default_vocab_word do
    base_word { 'bar' }
    language { 'es' }
    lesson
    program
    target_definition { 'baz' }
    target_word { 'foo' }
  end
end
