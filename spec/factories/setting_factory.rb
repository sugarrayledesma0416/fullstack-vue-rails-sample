FactoryBot.define do
  factory :setting do
    user
    name { 'gradebook__category_view' }
    value { 'weeks' }
  end
end
