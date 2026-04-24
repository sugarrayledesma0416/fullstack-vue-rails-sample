describe ExpressCourseCreator do
  include TimeHandler

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program) }
  let(:activity) { create(:activity) }
  let(:school) { create(:school) }
  let(:standard_set_1) { create(:standard_set, display_name: 'standard_set_1') }
  let(:standard_set_2) { create(:standard_set, display_name: 'standard_set_2') }
  let(:course) do
    create(
      :program_config_with_standard_sets,
      program:,
      supported_standard_sets: [standard_set_1, standard_set_2]
    )
    create(
      :course,
      program:,
      standard_sets: [standard_set_1, standard_set_2]
    )
  end

  let(:args) do
    {
      course: {
        school_id: school.id,
        name: 'Foo Course',
        start_date: Time.zone.today.to_s,
        end_date: Date.tomorrow.to_s,
        first_unit_id: course.first_unit_id,
        last_unit_id: course.last_unit_id,
        course_package_ids: [9, 10],
        course_library_from: 1,
        copy_created_activities_from_previous_course: false,
        selected_learning_track: 'Fully Online: Essentials',
        standard_set_ids: [standard_set_1.id, standard_set_2.id],
        categories_attributes:
        [
          { name: 'Homework', weighting_percent: 30, rank: 1 },
          { name: 'Tests', weighting_percent: 50, rank: 2 },
          { name: 'Quizzes', weighting_percent: 20, rank: 3 }
        ]
      },
      sections: ['Bar Section'],
      assignments: {
        Date.tomorrow.to_s => [
          {
            id: activity.id,
            group_id: nil,
            category: 'Homework',
            individually_assignable: true
          }
        ]
      },
      categories: {
        Learn: { name: 'Homework', weighting_percent: 30, rank: 1 },
        Practice: { name: 'Tests', weighting_percent: 50, rank: 2 },
        Interact: { name: 'Quizzes', weighting_percent: 20, rank: 3 }
      },
    }
  end

  let(:assignment_args) do
    {
      Date.tomorrow.to_s => [
        {
          id: activity.id,
          group_id: nil,
          category: 'Homework',
          individually_assignable: false
        }
      ]
    }
  end

  let(:creator) { described_class.new(instructor, program, args) }

  # Around each example, freeze time to Time.current (rails method) and 'turn off' timecop after use.
  around(:example) do |example|
    Timecop.freeze(Time.current, &example)
    Timecop.return
  end

  describe '#create' do
    before do
      allow(CourseLicenseCreatorWorker).to receive(:perform_in)
      allow(BulkAssignmentWorker).to receive(:perform_async)
      allow(CopyExternalItemsWorker).to receive(:perform_async)
    end

    it 'creates a course' do
      Course.destroy(course.id)
      expect { creator.create }.to change(Course, :count).by(1)
      course =
        Course.find_by(name: args[:course][:name], school_id: args[:course][:school_id])
      expect(course.course_package_ids).to eq args[:course][:course_package_ids]
    end

    it 'creates the course categories' do
      expect { creator.create }.to change(Category, :count).by(3)
    end

    it 'creates a course with help requests and score review ' \
       'disabled when program is supersite junior' do
      program.update!(family: 'supersites_jr')

      creator.create

      course = Course.last

      expect(course).to have_attributes(
        allows_help_requests: false,
        allows_review_requests: false
      )
    end

    it 'creates a course with chat level set to disabled when the school has ' \
       'chat support disabled' do
      create(:school_config, school:, chat_support_disabled: true)

      creator.create

      course = Course.last

      expect(course).to have_attributes(
        chat_level: 'disabled'
      )
    end

    it 'creates a course with standards' do
      creator.create
      expect(course.standard_set_ids)
        .to match_array([standard_set_1.id, standard_set_2.id])
    end

    it 'creates sections' do
      due_time = set_time_from_params('11', '59', 'PM')
      expect { creator.create }.to change(Section, :count).by(1)
      expect(
        Section.where(
          name: 'Bar Section',
          time_zone: Time.zone.name,
          due_time: due_time.strftime("%H:%M:%S"),
          instructor_id: instructor.id
        )).to exist
      expect(SectionInstructor.where(user_id: instructor.id, role: 'Instructor')).to exist
    end

    it 'spawns job to create assignments' do
      course = create(:course)
      section = create(:section)
      job_id = 'deadbeef'
      allow(Course).to receive(:create!).and_return(course)
      allow(Section).to receive(:new).and_return(section)
      allow(BulkAssignmentWorker).to receive(:perform_async).with(
        [section.id],
        course.id,
        assignment_args,
        args[:categories],
        args[:source_section_id]
      ).and_return(job_id)

      creator.create

      expect(BulkAssignmentWorker).to have_received(:perform_async).with(
        [section.id],
        course.id,
        assignment_args,
        args[:categories],
        args[:source_section_id]
      )

      expect(creator.job_id).to eq(job_id)
    end

    it 'creates course licenses' do
      course = create(:course)
      allow(Course).to receive(:create!).and_return(course)
      expect(CourseLicenseCreatorWorker).to receive(:perform_in).with(
        3.seconds, course.guid, [9, 10]
      )
      creator.create
    end

    describe 'when course is created with express setup' do
      it 'course created with learning track' do
        creator.create

        expect(JSON.parse(Course.last.course_config_json)['express_course_copied']).to be false
        expect(JSON.parse(Course.last.course_config_json)['learning_track']).to eq('Fully Online: Essentials')
      end

      it 'returns false if the course is supersite junior' do
        allow(program).to receive(:supersite_junior?).and_return(false)
        creator.create

        expect(JSON.parse(Course.last.course_config_json)['supersite_jr']).to be false
      end

      context 'course created as a copy of a previously created course' do
        it 'returns true if course was created as a copy of a previously course' do
          args[:course][:copy_created_activities_from_previous_course] = true
          args[:course][:selected_learning_track] = ''
          creator.create

          expect(JSON.parse(Course.last.course_config_json)['express_course_copied']).to be true
          expect(JSON.parse(Course.last.course_config_json)['learning_track']).to eq('')
        end

        it 'returns course copied id if course was created as a copy of a previously course' do
          args[:course][:copy_created_activities_from_previous_course] = true
          args[:course][:course_library_from] = 1
          args[:course][:selected_learning_track] = ''
          creator.create

          expect(JSON.parse(Course.last.course_config_json)['express_course_copied']).to be true
          expect(JSON.parse(Course.last.course_config_json)['course_copied_id']).to eq(1)
        end
      end
    end

    describe 'when copy_igc is checked' do
      let(:course) { create(:course) }
      let(:category_1) { create(:category, name: 'cat_1', course: course) }
      let(:category_2) { create(:category, name: 'cat_2', course: course) }
      let(:section_1) { create(:section, name: 'section_1', course: course) }
      let(:section_2) { create(:section, name: 'section_2', course: course) }

      before do
        category_1
        category_2
        section_1
        section_2
        course.reload

        args[:copy_igc] = true
      end

      it 'spawns a job to create external_items' do
        allow(Course).to receive(:create!).and_return(course)
        allow(CopyExternalItemsWorker).to receive(:perform_async)

        creator.create

        course.sections.each do |section|
          expect(CopyExternalItemsWorker).to have_received(:perform_async)
            .with(section.id, args[:src_section_id], true, args[:categories].to_h)
        end
      end
    end

    describe 'when copy_igc is not checked' do
      let(:course) { create(:course) }

      before do
        args[:copy_igc] = false
      end

      it 'does not spawn a job to create external_items' do
        allow(Course).to receive(:create!).and_return(course)
        allow(CopyExternalItemsWorker).to receive(:perform_async)

        creator.create

        expect(CopyExternalItemsWorker).not_to have_received(:perform_async)
      end
    end

    describe 'external items copying' do
      let(:source_section_id) { 123 }
      let(:args_with_copy_igc) do
        args.merge(
          copy_igc: true,
          src_section_id: source_section_id
        )
      end

      let(:creator_with_copy_igc) { described_class.new(instructor, program, args_with_copy_igc) }

      it 'copies external items when copy_igc is true' do
        course = create(:course)
        section = create(:section, course: course)
        allow(Course).to receive(:create!).and_return(course)
        creator_with_copy_igc.create

        expect(CopyExternalItemsWorker).to have_received(:perform_async).with(
          section.id,
          source_section_id,
          true,
          args[:categories].to_h
        )
      end

      it 'does not copy external items when copy_igc is false' do
        creator.create
        expect(CopyExternalItemsWorker).not_to have_received(:perform_async)
      end

      it 'copies external items for each section in the course' do
        course = create(:course)
        section1 = create(:section, course: course)
        section2 = create(:section, course: course)
        allow(Course).to receive(:create!).and_return(course)
        creator_with_copy_igc.create

        expect(CopyExternalItemsWorker).to have_received(:perform_async).with(
          section1.id,
          source_section_id,
          true,
          args[:categories].to_h
        )
        expect(CopyExternalItemsWorker).to have_received(:perform_async).with(
          section2.id,
          source_section_id,
          true,
          args[:categories].to_h
        )
      end
    end
  end
end
