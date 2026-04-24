FactoryBot.define do
  factory :default_vocab_tag do
    name { 'foo_tag' }
    default_vocab_word
  end
end
