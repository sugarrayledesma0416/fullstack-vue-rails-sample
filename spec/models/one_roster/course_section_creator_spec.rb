describe OneRoster::CourseSectionCreator do
  let(:program) { create(:program_with_lessons) }
  let(:instructor) { create(:instructor) }
  let(:school) { create(:school, salesforce_id: school_salesforce_id) }
  let(:start_date) { 1.day.ago }
  let(:end_date) { 1.day.from_now }
  let(:course_external_id) { SecureRandom.uuid }
  let(:class_external_id) { SecureRandom.uuid }
  let(:school_salesforce_id) { SecureRandom.uuid }
  let(:course_name) { 'RA Course' }
  let(:section_name) { 'RA Section' }
  let(:course_section_data) do
    {
      'section' => {
                     'course_external_id' => course_external_id,
                     'class_external_id' => class_external_id,
                     'salesforce_id' => school.salesforce_id,
                     'start_date' => start_date.strftime(OneRoster::CourseSectionCreator::DATE_FORMAT),
                     'end_date' => end_date.strftime(OneRoster::CourseSectionCreator::DATE_FORMAT)
                   }
    }
  end
  let(:roster_assistant_data) do
    [
      {
        'sourced_id' => course_external_id,
        'title' => course_name,
        'classes' => [
                       {
                         'sourced_id' => class_external_id,
                         'title' => section_name,
                         'school_salesforce_id' => school.salesforce_id
                       }
                     ]
      }
    ]
  end
  let(:roster_assistant_client) do
    instance_double(OneRoster::Client, courses_for_school: roster_assistant_data,
                                       last_request_successful?: true)
  end
  let(:creator) { described_class.new(course_section_data, program, instructor) }
  let(:start_date) { 1.day.ago }
  let(:end_date) { 10.days.from_now }
  let(:academic_sessions) do
    [
      {
        'start_date' => start_date.strftime('%Y-%m-%d'),
        'end_date' => end_date.strftime('%Y-%m-%d'),
        'school_year' => Time.now.strftime('%Y')
      }
    ]
  end

  let(:course_options) { instance_double(CourseOptions) }
  let(:available_course_package_ids) { [99] }

  before do
    basic_category = {
      name: 'Homework',
      weighting_percent: 100,
      credit_only: false,
      max_attempts: 2,
      enhanced_feedback_disabled: false,
      accept_late_work: true,
      late_work_penalty: 'percent_per_day',
      penalty_percent: 5,
      rank: 1,
      scoring_rulesets_attributes: [ScoringRuleset.new_course_defaults]
    }
    create(:one_roster_linked_user, user: instructor, school: school)
    allow(OneRoster::Client).to receive(:new).with(instructor.one_roster_linked_user.external_username)
                                             .and_return(roster_assistant_client)
    allow(CourseLicenseCreatorWorker).to receive(:perform_in)
    allow(course_options).to receive(:available_course_package_ids)
      .and_return(available_course_package_ids)
    allow(course_options).to receive(:basic_category).and_return(basic_category)
    allow(CourseOptions).to receive(:new).and_return(course_options)
  end

  describe '#create_course_and_section' do
    context 'with valid params' do
      it 'creates a course' do
        expect do
          creator.create_course_and_section
        end.to change(Course, :count).by(1)
        expect(Course.last).to have_attributes(
          chat_level: 'partner_chat',
          name: course_name,
          start_date: start_date.to_date,
          end_date: end_date.to_date,
          course_config_json: {
            setup_method: '',
            supersite_jr: program.supersite_junior?,
            express_course_copied: '',
            course_copied_id: '',
            learning_track: '',
            streamlined_rostering_setup: 'RA'
          }.to_json,
        )
      end

      it 'creates a course with the chat disabled when the school has disabled chat support' do
        create(:school_config, school:, chat_support_disabled: true)

        expect do
          creator.create_course_and_section
        end.to change(Course, :count).by(1)

        expect(Course.last).to have_attributes(
          chat_level: 'disabled',
          name: course_name,
          start_date: start_date.to_date,
          end_date: end_date.to_date,
          course_config_json: {
            setup_method: '',
            supersite_jr: program.supersite_junior?,
            express_course_copied: '',
            course_copied_id: '',
            learning_track: '',
            streamlined_rostering_setup: 'RA'
          }.to_json,
        )
      end

      it 'creates a course with course config' do
        expect do
          creator.create_course_and_section
        end.to change(Course, :count).by(1)
        expect(Course.last).to have_attributes(
          course_config_json: {
            setup_method: '',
            supersite_jr: program.supersite_junior?,
            express_course_copied: '',
            course_copied_id: '',
            learning_track: '',
            streamlined_rostering_setup: 'RA'
          }.to_json,
        )
      end

      it 'creates a section' do
        expect do
          creator.create_course_and_section
        end.to change(Section, :count).by(1)
        expect(Section.last).to have_attributes(
          name: section_name
        )
      end

      it 'creates a linked section' do
        expect do
          creator.create_course_and_section
        end.to change(OneRoster::LinkedSection, :count).by(1)
        linked_section = OneRoster::LinkedSection.last
        expect(linked_section.course_external_id).to eq course_external_id
        expect(linked_section.class_external_id).to eq class_external_id
        expect(linked_section.section).to eq Section.last
        expect(linked_section.school).to eq instructor.one_roster_linked_user.school
      end

      it 'creates a linked section without academic session if no academic session dates are present' do
        roster_assistant_data.first['classes'].first['academic_sessions'] = []
        creator.create_course_and_section
        linked_section = OneRoster::LinkedSection.last
        expect(linked_section.academic_session).to be_nil
      end

      it 'creates a linked section with academic session dates if they are present' do
        roster_assistant_data.first['classes'].first['academic_sessions'] = academic_sessions
        creator.create_course_and_section
        linked_section = OneRoster::LinkedSection.last
        expect(linked_section.academic_session).to match_array academic_sessions
      end

      it 'queues the course license creation with a 3 second delay' do
        creator.create_course_and_section
        expect(CourseLicenseCreatorWorker)
          .to have_received(:perform_in)
          .with(3.seconds, anything, anything)
      end

      context 'when there are level and component type course packages for the program' do
        it 'queues the course license creation' do
          creator.create_course_and_section

          expect(CourseLicenseCreatorWorker)
            .to have_received(:perform_in)
            .with(3.seconds, Course.last.guid, available_course_package_ids)
        end
      end

      it 'builds a notifications array' do
        creator.create_course_and_section
        expect(creator.notices).to include "Section '#{section_name}' has been created."
      end

      it 'creates a section with time_zone and due_time' do
        random_time_zone = ActiveSupport::TimeZone.all.sample.name
        instructor.time_zone = random_time_zone
        instructor.save!
        creator.create_course_and_section
        section = Section.last
        expect(section.time_zone).to eq random_time_zone
        expect(section.due_time.strftime('%H:%M:%S')).to eql '23:59:00'
      end

      it 'set the time_zone to Eastern if the instructor has not set a timezone' do
        instructor.time_zone = nil
        instructor.save!
        creator.create_course_and_section
        section = Section.last
        expect(section.time_zone).to eq 'Eastern Time (US & Canada)'
      end

      it 'applies all the standard sets associated with a program to the course config' do
        standard_set_1 =  create(:standard_set)
        standard_set_2 =  create(:standard_set)
        create(
          :program_config_with_standard_sets,
          program:,
          supported_standard_sets: [standard_set_1, standard_set_2]
        )
        creator.create_course_and_section
        expect(Course.last.standard_set_ids).to contain_exactly(
          standard_set_1.id, standard_set_2.id
        )
      end

      it 'does not apply any standards to the course config when the program has no ' \
         'associated standard sets' do
        create(
          :program_config,
          program:
        )
        creator.create_course_and_section
        expect(Course.last.standard_set_ids).to be_empty
      end

      it 'sets the section as closed for enrollments' do
        creator.create_course_and_section
        section = Section.last
        expect(section).not_to be_open_to_students
      end
    end

    context 'with invalid params' do
      context 'with missing section data' do
        let(:roster_assistant_data) do
          [
            {
              'sourced_id' => course_external_id,
              'title' => course_name,
              'classes' => [
                             {
                               'sourced_id' => class_external_id,
                               'title' => nil,
                               'school_salesforce_id' => school.salesforce_id
                             }
                           ]
            }
          ]
        end

        it 'builds an errors array' do
          creator.create_course_and_section
          expected_errors = [
            'Section  could not be created:',
            'Name is required'
          ]
          expect(creator.errors).to match_array expected_errors
        end
      end

      context 'with missing course data' do
        let(:course_section_data) do
          {
            'section' => {
                           'course_external_id' => course_external_id,
                           'class_external_id' => class_external_id,
                           'salesforce_id' => school.salesforce_id
                         }
          }
        end

        it 'builds an errors array' do
          creator.create_course_and_section
          expected_errors = [
            "Course #{course_name} could not be created:",
            'Start date is required.',
            'End date is required.'
          ]
          expect(creator.errors).to match_array expected_errors
        end
      end
    end
  end

  describe '#check_and_associate_as_co_instructor' do
    let(:other_instructor) { create(:instructor) }
    let(:creator) { described_class.new(nil, program, instructor) }

    it 'creates a section instructor with role Co-instructor for each one of the courses listed' do
      section = create(:section, instructor_id: other_instructor.id)
      one_roster_linked_section = create(:one_roster_linked_section,
                                         section_id: section.id,
                                         course_external_id: course_external_id,
                                         class_external_id: class_external_id)
      creator.check_and_associate_as_co_instructor
      expect(section.section_instructors.reload.count).to eq 2
      section_instructors = section.section_instructors.where(role: 'Co-instructor').reload
      expect(section_instructors.count).to eq 1
      expect(section_instructors.first.user_id).to eq instructor.id
    end

    it 'does not create new section instructor record when I am already the instructor of the section' do
      section = create(:section, instructor_id: instructor.id)
      one_roster_linked_section = create(:one_roster_linked_section,
                                         section_id: section.id,
                                         course_external_id: course_external_id,
                                         class_external_id: class_external_id)
      creator.check_and_associate_as_co_instructor
      section_instructors = section.section_instructors.reload
      expect(section_instructors.count).to eq 1
      expect(section_instructors.last.role).to eq 'Instructor'
      expect(section_instructors.last.user_id).to eq instructor.id
    end

    it 'does not create new section instructor record when I am already a co-instructor of the section' do
      section = create(:section_with_course,
                       instructor_id: other_instructor.id)
      one_roster_linked_section = create(:one_roster_linked_section,
                                         section_id: section.id,
                                         course_external_id: course_external_id,
                                         class_external_id: class_external_id)
      section_instructor = create(:section_co_instructor, instructor: instructor, section: section)
      creator.check_and_associate_as_co_instructor
      section_instructors = section.section_instructors.reload
      expect(section_instructors.count).to eq 2
      expect(section_instructors.find_by(role: 'Instructor').user_id).to eq other_instructor.id
      expect(section_instructors.find_by(role: 'Co-instructor').user_id).to eq instructor.id
    end
  end
end
