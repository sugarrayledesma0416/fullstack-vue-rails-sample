FactoryBot.define do
  factory :help_entry, class: HelpEntry do
    association :created_by, factory: :user
    page { 'factory#action' }
    published { true }
    url { 'http://factory.url' }
  end
end
