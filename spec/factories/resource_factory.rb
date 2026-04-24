FactoryBot.define do
  factory :resource, class: Resource do
    file_name { 'test_file' }
    file_type { 'Document' }
    program
    resource_component
    source { 'VHL' }
    sequence(:title) { |n| "Resource #{n}" }
  end

  factory :uploaded_resource, parent: :resource do
    sequence(:title) { |n| "Uploaded Resource #{n}" }
    uploaded { true }
  end
end
