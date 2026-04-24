describe Lti::CourseSectionCreator do
  let(:school) { create(:school) }
  let(:program) { create(:program_with_lessons) }
  let!(:instructor) { create(:instructor, schools: [school]) }
  let(:owner) { create(:instructor, schools: [school]) }
  let(:data) do
    {
      context_id: SecureRandom.uuid,
      context_label: 'Context label',
      context_title: 'Context title',
      lti_platform_guid: SecureRandom.uuid,
      school_guid: school.guid
    }
  end

  # TODO: There's a logic error in the course_end_date method of
  # the class. When the specified course_start_date is close to
  # the end of the year, the end date is calculated using
  # Time.zone.now.year. This means if the code executes in 2024 and
  # specifies a start date of January 2, 2025, and end date of
  # July 31, 2024 will be produced, causing validation failures:
  # ActiveRecord::RecordInvalid: Validation failed: End date should not be
  # in the past., Start date must come before End date
  # The method should instead use course_start_date.year.
  # When this is done, this base_date var can be removed and the
  # previous base_date (Time.now) can be used to reveal the error.
  # The error is obscured by this rescue in create_course_and_section.
  #     rescue ActiveRecord::ActiveRecordError => e
  let(:base_date) do
    if Time.now >= Time.parse("#{Time.now.year}-12-29")
      Time.now - 2.days
    else
      Time.now
    end
  end

  let!(:course_start_date) { base_date + 2.days }
  let!(:course_end_date) { base_date + 2.months }

  let(:data_with_dates) do
    {
      school_guid: school.guid,
      context_id: SecureRandom.uuid,
      lti_platform_guid: SecureRandom.uuid,
      context_label: 'Context label',
      context_title: 'Context title',
      course_start_date: course_start_date.to_s,
      course_end_date: course_end_date.to_s
    }
  end
  let(:course_section_name) { data[:context_id] }
  let(:start_date_before_july_end) { Time.zone.parse('2020-06-01') }
  let(:end_date_july_end) { Time.zone.parse('2020-07-31') }
  let(:start_date_after_july) { Time.zone.parse('2020-08-01') }
  let(:end_date_after_july) { Time.zone.parse('2021-07-31') }
  let(:creator) { described_class.new(data, instructor, program.id) }
  let(:creation_error) {  'Either Course or Section failed creation' }
  let(:course_license) { instance_double(Maestro::CourseLicense) }

  let(:grant_results) do
    {
      'errors' => [],
      'use_site_license' => true,
      'results' => {
        'normal' => [],
        'soft' => [],
        'hard' => []
      }
    }
  end
  let(:revoke_results) { { 'rollback_id' => 1, 'errors' => [] } }
  let(:course_access) do
    instance_double(Maestro::CourseAccess,
                    enough_for_course_duration?: true,
                    enough_for_today?: true)
  end

  let(:course_options) { instance_double(CourseOptions) }
  let(:available_course_package_ids) { [99] }
  let(:lti_platform) { create(:lti_platform) }

  def create_context_link(section)
    create( :lti_context_link,
            section_id: section.id,
            context_id: data[:context_id],
            lti_platform: lti_platform
    )
  end

  def create_linked_section(owner)
    section = create(:section_with_course, instructor: owner)
    create( :lti_context_link,
            section_id: section.id,
            context_id: data[:context_id],
            lti_platform: lti_platform
    )
    section
  end

  before do
    stub_const('MockCoursePackage', Struct.new(:id))
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

    allow(CourseLicenseCreatorWorker).to receive(:perform_in)
    # allow(course_options).to receive(:available_course_packages)
    #   .and_return(course_packages)
    allow(course_options).to receive(:available_course_package_ids)
      .and_return(available_course_package_ids)
    allow(course_options).to receive(:basic_category).and_return(basic_category)
    allow(CourseOptions).to receive(:new).and_return(course_options)
    allow(Maestro::User).to receive(:grant_multiple_site_license_seats)
      .and_return(grant_results)
    allow(Maestro::CourseAccess).to receive(:find_for_user_and_course)
      .and_return(course_access)
    allow(Maestro::User).to receive(:revoke_site_license_seat).and_return(revoke_results)
    allow(Assignment).to receive(:find_with_course_category).and_return(nil)
    allow(Maestro::Enrollment).to receive(:check_licenses).and_return('enrollment_guids' => [])
    allow(Maestro::User).to receive(:ensure_instructor_access_matches_site_license)
    allow(Lti::Platform).to receive(:find_by).and_return(lti_platform)
  end

  def expected_end_date(start_date)
    if start_date.month < 7
      "#{Time.zone.now.year}-07-31"
    else
      "#{Time.zone.now.year + 1}-07-31"
    end
  end

  describe '#process' do
    RSpec.shared_examples 'instructor program access check' do
      it 'checks if the instructor access to the program matches the school site license' do
        creator.process
        expect(Maestro::User).to have_received(:ensure_instructor_access_matches_site_license)
          .with(instructor.guid, [school.guid])
      end
    end

    context 'when an active section is not linked to the context ID in the database' do
      include_examples 'instructor program access check'

      it 'creates the course' do
        expect do
          creator.process
        end.to change(Course, :count).by(1)
        expect(Course.last).to have_attributes(
          chat_level: 'partner_chat',
          name: data[:context_title],
          owner_id: instructor.id,
          program:,
          school:,
          course_config_json: {
            setup_method: '',
            supersite_jr: program.supersite_junior?,
            express_course_copied: '',
            course_copied_id: '',
            learning_track: '',
            streamlined_rostering_setup: 'LTI-A-R'
          }.to_json
        )
      end

      it 'creates the course with the chat disabled when the school has disabled chat support' do
        create(:school_config, school:, chat_support_disabled: true)

        expect do
          creator.process
        end.to change(Course, :count).by(1)

        expect(Course.last).to have_attributes(
          chat_level: 'disabled',
          name: data[:context_title],
          owner_id: instructor.id,
          program:,
          school:,
          course_config_json: {
            setup_method: '',
            supersite_jr: program.supersite_junior?,
            express_course_copied: '',
            course_copied_id: '',
            learning_track: '',
            streamlined_rostering_setup: 'LTI-A-R'
          }.to_json
        )
      end

      it 'creates the section' do
        expect do
          creator.process
        end.to change(Section, :count).by(1)
        expect(Section.last).to have_attributes(
          name: data[:context_title],
          instructor_id: instructor.id,
          course: Course.last
        )
      end

      it 'creates the section instructor with role instructor' do
        expect do
          creator.process
        end.to change(SectionInstructor, :count).by(1)

        expect(SectionInstructor.where(role: 'Instructor')).to contain_exactly(
          an_object_having_attributes(
            user_id: instructor.id,
            section: Section.last
          )
        )
      end

      context 'when an archived section exists for the UA-linked section_guid' do
        let(:creator) do
          described_class.new(data.merge(section_guid: section.guid), owner, program.id)
        end
        let(:section) { create_linked_section(owner) }

        before do
          section.update_column(:is_archived, true)
        end

        it 'does not create a new course' do
          expect { creator.process }.not_to change(Course, :count)
        end

        it 'does not create a new section' do
          expect { creator.process }.not_to change(Section, :count)
        end

        it 'does not change the archived section' do
          expect { creator.process }.not_to change(section, :updated_at)
        end

        it 'reports an error' do
          msg = 'Unable to create a new section for LMS context because ' \
                'the previous section was not successfully deleted.'

          creator.process
          expect(creator.errors[:save]).to eq(msg)
        end
      end
    end

    context 'when an active section is linked to the context id exists in the database,' do
      let(:update_creator) { described_class.new(data.merge(context_label: 'New Name'), instructor, program.id) }
      let!(:existing_section) { create_linked_section(owner) }

      include_examples 'instructor program access check'

      it 'creates a section instructor with role Co-instructor' do
        expect do
          update_creator.process
        end.to change(SectionInstructor, :count).by(1)
        expect(SectionInstructor.where(role: 'Co-instructor')).to contain_exactly(
          an_object_having_attributes(
            user_id: instructor.id,
            section: existing_section
          )
        )
        expect(Maestro::User).to have_received(:ensure_instructor_access_matches_site_license)
          .with(instructor.guid, [school.guid])
      end

      it 'updates the name of the existing course but not the section' do
        sec_name = existing_section.name
        expect do
          update_creator.process
        end.to not_change(Course, :count)
           .and not_change(Section, :count)
        existing_section.reload
        expect(existing_section.name).to eq sec_name
        expect(existing_section.course.name).to eq 'Context title'
      end

      it 'reports an error when updates to an existing course fail' do
        allow_any_instance_of(Course).to receive(:save).and_return(false)
        expect do
          update_creator.process
        end.to not_change(Course, :count)
        existing_section.reload
        expect(existing_section.course.name).not_to eq 'New Name'
        expect(update_creator.errors[:save]).to include "Course with guid: #{existing_section.course.guid} update failed"
      end
    end
  end

  # TODO: Given changes under https://vistahl.atlassian.net/browse/MAE-69272,
  #       the logic for these tests should mostly be removed.
  # TODO: These tests are not time zone safe. If any are kept, refactor to use Timecop.
  describe '#create_course_and_section' do
    context 'with valid params' do
      context "when the course creation's month is after July" do
        it 'creates a course with end_date the current year' do
          allow(Time).to receive(:now).and_return(start_date_before_july_end)
          expect do
            creator.create_course_and_section
          end.to change(Course, :count).by(1)
          expect(Course.last).to have_attributes(
            name: data[:context_title],
            owner_id: instructor.id,
            program_id: program.id,
            start_date: start_date_before_july_end.to_date,
            end_date: end_date_july_end.to_date,
            school_id: school.id
          )
        end
      end

      context "when the course creation's month is before July" do
        it 'creates a course with end_date the next year' do
          allow(Time).to receive(:now).and_return(start_date_after_july)
          expect do
            creator.create_course_and_section
          end.to change(Course, :count).by(1)
          expect(Course.last).to have_attributes(
            name: data[:context_title],
            owner_id: instructor.id,
            program_id: program.id,
            start_date: start_date_after_july.to_date,
            end_date: end_date_after_july.to_date,
            school_id: school.id
          )
        end
      end

      context "when the course creation start and end dates are supplied in parameters" do
        it 'creates a course with both dates from parameters' do
          cs_creator = described_class.new(data_with_dates, instructor, program.id)
          expect do
            cs_creator.create_course_and_section
          end.to change(Course, :count).by(1)
          expect(Course.last).to have_attributes(
            name: data_with_dates[:context_title],
            owner_id: instructor.id,
            program_id: program.id,
            start_date: course_start_date.to_date,
            end_date: course_end_date.to_date,
            school_id: school.id
          )
        end

        it 'adjusts the end date if the date in params is before the start date' do
          bad_crs_end_date = course_start_date - 1.month
          bad_data = data_with_dates.merge(course_end_date: bad_crs_end_date.to_s)
          cs_creator = described_class.new(bad_data, instructor, program.id)
          expect do
            cs_creator.create_course_and_section
          end.to change(Course, :count).by(1)
          expect(Course.last).to have_attributes(
            name: bad_data[:context_title],
            owner_id: instructor.id,
            program_id: program.id,
            start_date: course_start_date.to_date,
            end_date: expected_end_date(course_start_date).to_date,
            school_id: school.id
          )
        end

        it 'adjusts the end date if the date in params is the same date as the start date' do
          bad_crs_end_date = course_start_date
          bad_data = data_with_dates.merge(course_end_date: bad_crs_end_date.to_s)
          cs_creator = described_class.new(bad_data, instructor, program.id)
          expect do
            cs_creator.create_course_and_section
          end.to change(Course, :count).by(1)
          expect(Course.last).to have_attributes(
                                   name: bad_data[:context_title],
                                   owner_id: instructor.id,
                                   program_id: program.id,
                                   start_date: course_start_date.to_date,
                                   end_date: expected_end_date(course_start_date).to_date,
                                   school_id: school.id
                                 )
        end

        it 'uses start_date from parameters even when end date not present' do
          missing_date_data = data_with_dates.merge(course_end_date: nil)
          cs_creator = described_class.new(missing_date_data, instructor, program.id)
          expect do
            cs_creator.create_course_and_section
          end.to change(Course, :count).by(1)
          expect(Course.last).to have_attributes(
            name: missing_date_data[:context_title],
            owner_id: instructor.id,
            program_id: program.id,
            start_date: course_start_date.to_date,
            end_date: expected_end_date(course_start_date).to_date,
            school_id: school.id
          )
        end

        it 'uses end date from parameters even when start date not present' do
          missing_date_data = data_with_dates.merge(course_start_date: nil)
          cs_creator = described_class.new(missing_date_data, instructor, program.id)
          expect do
            cs_creator.create_course_and_section
          end.to change(Course, :count).by(1)
          expect(Course.last).to have_attributes(
            name: missing_date_data[:context_title],
            owner_id: instructor.id,
            program_id: program.id,
            start_date: Time.zone.today,
            end_date: course_end_date.to_date,
            school_id: school.id
          )
        end
      end

      it 'uses context label as course name if the context title is nil' do
        data[:context_title] = nil
        creator.create_course_and_section
        expect(Course.last.name).to eq data[:context_label]
      end

      it 'sets allow_individual_assign to true' do
        expect do
          creator.create_course_and_section
        end.to change(Course, :count).by(1)
        expect(Course.last).to have_attributes(
          allow_individual_assign: true
        )
      end

      it 'creates the course with course config' do
        expect do
          creator.process
        end.to change(Course, :count).by(1)
        expect(Course.last).to have_attributes(
          course_config_json: {
            setup_method: '',
            supersite_jr: program.supersite_junior?,
            express_course_copied: '',
            course_copied_id: '',
            learning_track: '',
            streamlined_rostering_setup: 'LTI-A-R'
          }.to_json
        )
      end

      it 'creates a section' do
        expect do
          creator.create_course_and_section
        end.to change(Section, :count).by(1)
        expect(Section.last).to have_attributes(
          name: data[:context_title],
          instructor_id: instructor.id
        )
      end

      it 'assigns a section name if both the context label and context title are nil' do
        data[:context_title] = nil
        data[:context_label] = nil
        creator.create_course_and_section
        expect(Section.last.name).to eq course_section_name
      end

      it 'creates a section with time_zone and due_time' do
        time_zone = 'Azores'
        instructor.update!(time_zone: time_zone)
        creator.create_course_and_section
        section = Section.last
        expect(section.time_zone).to eq time_zone
        expect(section.due_time.strftime('%H:%M:%S')).to eql '23:59:00'
      end

      it 'sets the time_zone to Eastern if the instructor has not set a timezone' do
        instructor.update!(time_zone: nil)
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

      it 'creates a section instructor' do
        expect do
          creator.create_course_and_section
        end.to change(SectionInstructor, :count).by(1)
        expect(SectionInstructor.last).to have_attributes(
          user_id: instructor.id,
          section: Section.last,
          role: 'Instructor'
        )
      end

      context 'when there are level and component type course packages for the program' do
        it 'queues the course license creation' do
          creator.create_course_and_section

          expect(CourseLicenseCreatorWorker)
            .to have_received(:perform_in)
          .with(3.seconds, Course.last.guid, available_course_package_ids)
        end
      end
    end

    context 'with invalid params' do
      it 'builds an errors hash when data is missing' do
        data[:school_guid] = nil
        creator.create_course_and_section
        expected_error = 'Validation failed: School must exist'
        expect(creator.errors[:save]).to include expected_error
      end
    end

    context 'with failed Course or Section save' do
      it 'reports an error when new section save fails ' do
        allow(Section).to receive(:create!)
                      .and_raise(ActiveRecord::ActiveRecordError)
        expect do
          creator.create_course_and_section
        end.to not_change(Course, :count)
           .and not_change(Section, :count)
        expect(creator.errors[:save]).to include creation_error
      end

      it 'reports an error when new course save fails ' do
        allow(Course).to receive(:create!)
                     .and_raise(ActiveRecord::ActiveRecordError)
        expect do
          creator.create_course_and_section
        end.to not_change(Course, :count)
           .and not_change(Section, :count)
        expect(creator.errors[:save]).to include creation_error
      end
    end
  end

  describe '#check_and_associate_co_instructor' do
    before do
      create_linked_section(owner)
    end

    it 'creates a section instructor with role Co-instructor' do
      expect do
        creator.check_and_associate_co_instructor
      end.to change(SectionInstructor, :count).by(1)
      expect(SectionInstructor.where(role: 'Co-instructor')).to contain_exactly(
        an_object_having_attributes(
          user_id: instructor.id,
          section: Section.last
        )
      )
    end

    it 'does not create new section instructor record when I am already a co-instructor of the section' do
      section = Section.last
      create(:section_co_instructor, instructor: instructor, section: section)
      creator.check_and_associate_co_instructor
      expect(section.section_instructors.reload).to contain_exactly(
        an_object_having_attributes(
          user_id: owner.id,
          section_id: Section.last.id,
          role: 'Instructor'
        ),
        an_object_having_attributes(
          user_id: instructor.id,
          section_id: Section.last.id,
          role: 'Co-instructor'
        )
      )
      expect(Maestro::User).not_to have_received(:ensure_instructor_access_matches_site_license).
        with(instructor.guid, [school.guid])
    end

    it 'reports a section_instructor error when new section_instructor save fails ' do
      allow_any_instance_of(SectionInstructor).to receive(:save)
                                         .and_return(false)
      creator.check_and_associate_co_instructor
      expected_error = "Co-instructor could not be created"
      expect(creator.errors[:section_instructor]).to include expected_error
      expect(Maestro::User).not_to have_received(:ensure_instructor_access_matches_site_license).
        with(instructor.guid, [school.guid])
    end
  end

  describe '#success' do
    let(:section) { create(:section_with_course) }

    before do
      allow(creator).to receive(:existing_section).and_return(section)
      allow(creator).to receive(:section).and_return(section)
    end

    it 'returns false if there are any errors' do
      creator.errors[:some_error] = 'something went wrong.'
      expect(creator.success).to be_falsey
    end

    it 'returns false if there is no section' do
      allow(creator).to receive(:existing_section).and_return(nil)
      expect(creator.success).to be_falsey
    end
  end
end
