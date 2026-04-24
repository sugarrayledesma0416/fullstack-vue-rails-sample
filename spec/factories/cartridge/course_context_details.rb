FactoryBot.define do
  factory :cartridge_course_context_detail, class: 'Cartridge::CourseContextDetail' do |cd|
    cd.lms_context_id { SecureRandom.uuid }
    cd.lis_outcome_service_url { 'https://www.lms.com/outcome_service' }
    cd.is_archived { false }
    cd.association :course
    cd.association :section
    cd.association :school
  end
end
