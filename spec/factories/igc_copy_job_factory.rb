FactoryBot.define do
  factory :igc_copy_job do
    association :instructor
    association :src_program, factory: :program
    association :dest_program, factory: :program
  end
end
