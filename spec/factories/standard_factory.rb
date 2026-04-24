FactoryBot.define do
  factory :standard do
    sequence(:name) { |n| "Standard #{n}" }
    sequence(:description) { |n| "This standard does #{n}" }
    label { 'Grade Level Standard' }
    number { 'ELA.9.R.2.3.C2' }
    vendor_guid { SecureRandom.uuid }
    searchable { true }
    # additional_info { "{\"additional_info\":{\"ancestors\":\"#{SecureRandom.uuid}\"," \
    #                   "\"grade_levels\":'6,7,8',\"parent_guid\":\"#{SecureRandom.uuid}\"}}" }
    additional_info { JSON.generate({
                                          additional_info:
                                          {
                                            ancestors: "#{SecureRandom.uuid}",
                                            grade_levels:'6,7,8',
                                            parent_guid: "#{SecureRandom.uuid}"
                                          }
                                        })
                    }
    association :standard_set, factory: :standard_set
  end
end

