FactoryBot.define do
  factory :user_defined_word do
    lesson
    program
    target { 'factory target' }
    translation { 'factory translation' }
    user
  end
end
