FactoryBot.define do
  factory :scoring_ruleset do
    ignore_accents        { false }
    ignore_capitalization { false }
    ignore_punctuation    { false }
    category
  end
end
