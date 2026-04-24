describe DemoCourseBuild::Course do
  let(:program) { create(:program) }
  let(:school) { create(:school) }
  let(:model_instructor) { create(:instructor, username: 'model_demo_instructor') }
  let(:model_course) do
    create(
      :course,
      name: 'Trial Course',
      start_date: 100.days.ago,
      end_date: Date.today,
      program: program,
      owner: model_instructor
    )
  end
  let(:model_data) do
    instance_double(
      DemoCourseBuild::ModelData,
      model_course: model_course,
      model_section: build_stubbed(:section),
      model_data_exists?: true
    )
  end
  let(:demo_instructor) { create(:instructor) }

  let(:course_creator) { described_class.new(owner: demo_instructor, program: program) }

  before do
    allow(DemoCourseBuild::ModelData).to receive(:new).and_return(model_data)
    model_instructor.schools << school
    demo_instructor.schools << school
  end

  describe '#create_demo_course' do
    it 'creates a demo course' do
      results = course_creator.create_demo_course
      expect(results).to be_a DemoCourse
      expect(results).to be_valid
    end

    it 'creates a course with attributes copied from the model course' do
      demo_course = course_creator.create_demo_course
      matching_keys = DemoCourseBuild::Course::ATTRIBUTES_TO_CLONE.dup
      demo_shared_attrs = demo_course.attributes.select do |attr|
        matching_keys.include?(attr.to_sym)
      end
      model_shared_attrs = model_course.attributes.select do |attr|
        matching_keys.include?(attr.to_sym)
      end
      expect(demo_shared_attrs).to match model_shared_attrs
    end

    it 'creates a demo course with attributes specific to the demo instructor' do
      demo_course = course_creator.create_demo_course

      expect(demo_course).to have_attributes(
        chat_level: 'partner_chat',
        end_date: 92.days.from_now.to_date,
        is_demo: true,
        owner_id: demo_instructor.id,
        school_id: demo_instructor.schools.first.id,
        start_date: 8.days.ago.to_date
      )
    end

    it 'creates a demo course with the chat disabled when the school has disabled chat support' do
      create(:school_config, school:, chat_support_disabled: true)

      demo_course = course_creator.create_demo_course

      expect(demo_course).to have_attributes(
        chat_level: 'disabled',
        end_date: 92.days.from_now.to_date,
        is_demo: true,
        owner_id: demo_instructor.id,
        school_id: demo_instructor.schools.first.id,
        start_date: 8.days.ago.to_date
      )
    end

    it 'records an error if demo course data is missing' do
      expected_error_message = 'no model demo course was found'
      model_data = instance_double(
        DemoCourseBuild::ModelData,
        model_course: nil,
        model_section: build_stubbed(:section),
        model_data_exists?: false
      )
      allow(model_data).to receive(:errors)
        .and_return(ActiveModel::Errors.new(model_data))
      model_data.errors.add(:base, expected_error_message)

      allow(course_creator).to receive(:model_data).and_return(model_data)
      results = course_creator.create_demo_course
      expect(results).not_to be_valid

      expect(results.errors.full_messages).to eq([expected_error_message])
    end
  end
end
