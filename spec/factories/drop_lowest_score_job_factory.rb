FactoryBot.define do
  factory :drop_lowest_score_job do
    sequence(:section_id) { |n| n }
    sequence(:category_id) { |n| n }
    sequence(:user_id) { |n| n }
    enqueued { false }
  end
end
