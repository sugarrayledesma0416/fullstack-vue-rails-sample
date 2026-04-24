FactoryBot.define do
  factory :instructor_resource_setting do
    resource
    instructor
    student_visibility { '' }
  end

  factory :shown_instructor_resource_setting, parent: :instructor_resource_setting do
    student_visibility { InstructorResourceSetting.settings[:shown] }
  end

  factory :hidden_instructor_resource_setting, parent: :instructor_resource_setting do
    student_visibility { InstructorResourceSetting.settings[:hidden] }
  end
end
