FactoryBot.define do
  factory :bulk_resources_creation_tracker do
    csv_file_name { generate(:csv_file_name) }
    zip_file_name { generate(:zip_file_name) }
    state { 'pending' }
    logs { { data: [] }.to_json }
    program_id { create(:program).id }
  end

  sequence :csv_file_name do |n|
    "#{FFaker::Book.title}_#{n}.csv"
  end

  sequence :zip_file_name do |n|
    "#{FFaker::Book.title}_#{n}.zip"
  end
end
