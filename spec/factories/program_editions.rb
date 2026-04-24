FactoryBot.define do
  factory :program_edition do
    association :program, factory: :program

    next_edition_program_id { nil }
    previous_edition_program_id { nil }
  end
end
