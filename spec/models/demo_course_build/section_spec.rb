describe DemoCourseBuild::Section do
  let(:program) { create(:program) }
  let(:school) { create(:school, time_zone: 'Brasilia') }
  let(:model_instructor) do
    create(
      :instructor,
      username: 'model_demo_instructor',
      time_zone: 'Eastern Time (US & Canada)',
      schools: [school]
    )
  end
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
  let(:model_section) do
    create(
      :section,
      name: 'Trial Section',
      course: model_course,
      instructor: model_instructor
    )
  end
  let(:model_data) do
    instance_double(
      DemoCourseBuild::ModelData,
      model_course: model_course,
      model_section: model_section,
      model_data_exists?: true
    )
  end
  let(:demo_instructor) do
    create(
      :instructor,
      time_zone: 'Central Time (US & Canada)',
      schools: [school]
    )
  end

  let(:demo_course) do
    create(
      :course,
      name: 'Trial Course',
      start_date: 8.days.ago.to_date,
      end_date: 92.days.from_now.to_date,
      program: program,
      owner: demo_instructor,
      school: school
    )
  end
  let(:section_creator) do
    described_class.new(owner: demo_instructor, course: demo_course)
  end

  before do
    allow(DemoCourseBuild::ModelData).to receive(:new).and_return(model_data)
  end

  describe '#create_demo_section' do
    it 'creates a demo section' do
      results = section_creator.create_demo_section
      expect(results).to be_a ::Section
      expect(results).to be_valid
    end

    # leaving the role empty prevents the instructor from editing the demo section
    # the instructor can remove the section, however, so it doesn't hand around
    # in their old course list
    it 'creates a section instructor record with no role' do
      expect do
        section_creator.create_demo_section
      end.to change(SectionInstructor, :count).by(1)
      si = SectionInstructor.last
      expect(si.user_id).to eq demo_instructor.id
      expect(si.role).to be_blank
    end

    it 'creates a course with attributes copied from the model course' do
      demo_section = section_creator.create_demo_section
      matching_keys = DemoCourseBuild::Section::ATTRIBUTES_TO_CLONE.dup
      demo_shared_attrs = demo_section.attributes.select do |attr|
        matching_keys.include?(attr.to_sym)
      end
      model_shared_attrs = model_section.attributes.select do |attr|
        matching_keys.include?(attr.to_sym)
      end
      expect(demo_shared_attrs).to match model_shared_attrs
    end

    it 'creates a demo course with attributes specific to the demo instructor' do
      demo_section = section_creator.create_demo_section
      demo_keys = %w[instructor_id time_zone course_id]
      demo_unique_attrs = demo_section.attributes.slice(*demo_keys)

      expect(demo_unique_attrs['instructor_id']).to eq demo_instructor.id
      expect(demo_unique_attrs['time_zone']).to eq demo_instructor.time_zone
      expect(demo_unique_attrs['course_id']).to eq demo_course.id
    end

    context 'when the owner has a time zone' do
      it 'uses time zone of the owner' do
        demo_section = section_creator.create_demo_section
        expect(demo_section[:time_zone]).to eq(demo_instructor.time_zone)
      end
    end

    context 'when the owner has no time zone' do
      let(:demo_instructor) do
        create(:instructor, time_zone: nil)
      end

      it 'uses time zone of the school' do
        demo_section = section_creator.create_demo_section
        expect(demo_section[:time_zone]).to eq(school.time_zone)
      end

      context 'when the school has no time zone' do
        let(:school) { create(:school, time_zone: nil) }

        it 'uses default time zone' do
          demo_section = section_creator.create_demo_section
          expect(demo_section.time_zone).to eq(Time.zone.name)
        end
      end
    end

    it 'records an error if section creation fails' do
      expected_error_message = 'Name is required'
      section = build(:section, name: '')
      model_data = instance_double(
        DemoCourseBuild::ModelData,
        model_course: model_course,
        model_section: section,
        model_data_exists?: false
      )

      allow(section_creator).to receive(:model_data).and_return(model_data)
      results = section_creator.create_demo_section
      expect(results).to_not be_valid
      expect(results.errors.full_messages).to eq([expected_error_message])
    end
  end
end
