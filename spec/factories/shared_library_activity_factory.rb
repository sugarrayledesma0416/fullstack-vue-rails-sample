FactoryBot.define do
  factory :shared_library_activity do
    school
    is_shared { false }
  end
end
