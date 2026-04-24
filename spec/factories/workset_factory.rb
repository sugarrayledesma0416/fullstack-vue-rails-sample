FactoryBot.define do
  factory :workset do
    user
    section
    activity_list { '1,2,3,4,5,6' }
  end
end
