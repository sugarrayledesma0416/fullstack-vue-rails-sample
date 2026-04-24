FactoryBot.define do
  factory :program_to_program_mapping do |mapping|
    mapping.association :dest_program, factory: :program_with_toc_entries
    mapping.association :src_strand, factory: :concept
    dest_strand do
      association :concept, program: dest_program
    end
  end
end
