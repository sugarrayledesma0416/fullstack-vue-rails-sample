FactoryBot.define do
  factory :standards_results do
    sequence(:cms_activity_id) { |n| 10 + n }
    sequence(:section_id) { |n| 100 + n }
    sequence(:user_id) { |n| 1000 + n }
    results_data do
      {
        'test_guid' => {
          question_label: 'question_01',
          points_earned: 2,
          points_possible: 2
        }
      }
    end
  end
end
