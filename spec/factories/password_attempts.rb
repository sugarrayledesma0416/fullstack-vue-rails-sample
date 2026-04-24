FactoryBot.define do
  factory :password_attempt do
    id { '' }
    attempt_id { '' }
    password { 'MyString' }
    correct { '' }
  end
end
