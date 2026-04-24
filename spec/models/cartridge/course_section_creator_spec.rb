describe Cartridge::CourseSectionCreator do
  let(:school) { create(:school) }
  let(:program) { create(:program_with_lessons) }
  let(:activity) { create(:activity, lesson: program.lessons.first) }
  let(:activity_resource_link) { create(:cartridge_resource_link, resource_id: activity.id) }
  let(:resource) { create(:resource, program: program) }
  let(:downloadable_resource_resource_link) do
    create(:cartridge_resource_link, resource_id: resource.id, resource_type: 'resource')
  end
  let(:instructor_vtext_resource_link) do
    create(:cartridge_resource_link, resource_id: program.id, resource_type: 'instructor_vtext')
  end
  let(:student_vtext_resource_link) do
    create(:cartridge_resource_link, resource_id: program.id, resource_type: 'student_vtext')
  end
  let(:consumer) { create(:cartridge_consumer, school: school) }
  let!(:cartridge_contexts_owner) { create(:cartridge_contexts_owner, school: school) }
  let(:contexts_owner) { cartridge_contexts_owner.user }
  let(:instructor) { create(:cartridge_instructor_user_link, school: school).user }
  let(:student) { create(:cartridge_student_user_link, school: school).user }
  # legacy launch (CC 1.1) data
  let(:data) do
    {
      consumer_guid: consumer.guid,
      context_id: SecureRandom.uuid,
      context_label: 'Context label',
      context_title: 'Context title',
      launch_presentation_return_url: 'MyLaunchPresentationReturnUrl',
      lis_outcome_service_url: 'MyLisOutcomeServiceUrl',
      lis_result_sourcedid: SecureRandom.uuid,
      lti_version: '1.1.0'
    }
  end

  # new launch (CC 1.3) data
  let(:lti_platform) { create(:lti_platform, school: school, cartridge: true) }
  let(:line_items_url) { "https://lms.example.org/api/lti/courses/#{SecureRandom.uuid}" }
  let(:line_item_url) { "#{line_items_url}/line_item/#{rand(1..99)}" }
  let(:data_cc_1_3_0) do
    {
      context_id: SecureRandom.uuid,
      context_label: 'Context label',
      context_title: 'Context title',
      launch_presentation_return_url: 'MyLaunchPresentationReturnUrl',
      line_items_url: line_items_url,
      line_item_url: line_item_url,
      lti_version: '1.3.0',
      platform_guid: lti_platform.guid
    }
  end

  let(:course_section_name) { "course_section_#{data[:context_id]}" }
  let(:start_date_before_july) { Time.zone.parse('2020-06-01') }
  let(:end_date_before_july) { Time.zone.parse('2020-07-31') }
  let(:start_date_after_july) { Time.zone.parse('2020-08-01') }
  let(:end_date_after_july) { Time.zone.parse('2021-07-31') }
  let(:creator) { described_class.new(data, instructor, activity_resource_link) }
  let(:creator_with_resource) do
    described_class.new(data, instructor, downloadable_resource_resource_link)
  end
  let(:creator_with_instructor_vtext_link) do
    described_class.new(data, instructor, instructor_vtext_resource_link)
  end
  let(:creator_with_student_vtext_link) do
    described_class.new(data, instructor, instructor_vtext_resource_link)
  end
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

    # Stub to avoid actually sleeping during tests.
    allow(Kernel).to receive(:sleep)

    allow(CourseOptions).to receive(:new).and_return(course_options)
    allow(course_options).to receive(:available_course_package_ids)
      .and_return(available_course_package_ids)
    allow(course_options).to receive(:basic_category).and_return(basic_category)
    allow(CourseLicenseCreatorWorker).to receive(:perform_in)
    allow(Maestro::User).to receive(:grant_multiple_site_license_seats)
      .and_return(grant_results)
    allow(Maestro::CourseAccess).to receive(:find_for_user_and_course)
      .and_return(course_access)
    allow(Maestro::User).to receive(:revoke_site_license_seat).and_return(revoke_results)
    allow(Assignment).to receive(:find_with_course_category).and_return(nil)
    allow(Maestro::Enrollment).to receive(:check_licenses).and_return('enrollment_guids' => [])
    allow(Maestro::User).to receive(:ensure_instructor_access_matches_site_license)
  end

  describe '#process' do
    RSpec.shared_examples 'instructor program access check' do
      it 'checks if the instructor access to the program matches the school site license' do
        creator.process
        expect(Maestro::User).to have_received(:ensure_instructor_access_matches_site_license)
          .with(instructor.guid, [school.guid])
      end
    end

    context 'when the context id does not exist in the database' do
      include_examples 'instructor program access check'

      RSpec.shared_examples 'course, section and course context detail check' do
        it 'creates the course' do
          expect do
            creator.process
          end.to change(Course, :count).by(1)

          expect(Course.last).to have_attributes(
            chat_level: 'partner_chat',
            name: data[:context_title],
            owner_id: contexts_owner.id,
            program:
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
            owner_id: contexts_owner.id,
            program:
          )
        end

        it 'creates the section' do
          expect do
            creator.process
          end.to change(Section, :count).by(1)

          expect(Section.last).to have_attributes(
            name: data[:context_title],
            instructor_id: contexts_owner.id,
            course: Course.last
          )
        end

        it 'creates the course context detail' do
          expect do
            creator.process
          end.to change(Cartridge::CourseContextDetail, :count).by(1)

          expect(Cartridge::CourseContextDetail.last).to have_attributes(
            lms_context_id: data[:context_id],
            course: Course.last,
            section: Section.last,
            lis_outcome_service_url: data[:lis_outcome_service_url],
            line_items_url: data[:line_items_url]
          )
        end
      end

      RSpec.shared_examples 'instructor check' do
        it 'creates the section instructor with role instructor' do
          expect do
            creator.process
          end.to change(SectionInstructor, :count).by(2)
          expect(SectionInstructor.where(role: 'Instructor')).to contain_exactly(
            an_object_having_attributes(
              user_id: contexts_owner.id,
              section: Section.last
            )
          )
        end

        it 'creates the section instructor with role Co-instructor if the' \
          'current user is an instructor' do
          expect do
            creator.process
          end.to change(SectionInstructor, :count).by(2)
          expect(SectionInstructor.where(role: 'Co-instructor')).to contain_exactly(
            an_object_having_attributes(
              user_id: instructor.id,
              section: Section.last
            )
          )
        end
      end

      context 'when the launch is a legacy CC 1.1 launch' do
        context 'when the resource link is an activity' do
          include_examples 'course, section and course context detail check'
        end

        context 'when the resource link is a resource' do
          let(:creator) { creator_with_resource }
          include_examples 'course, section and course context detail check'
        end

        context 'when the resource link is a vtext_link' do
          let(:creator) { creator_with_instructor_vtext_link }
          include_examples 'course, section and course context detail check'
        end

        context 'when the current user is an instructor' do
          include_examples 'instructor check'
        end

        context 'when the current user is a student' do
          let(:creator) { described_class.new(data, student, activity_resource_link) }

          it 'creates the score destination' do
            expect do
              creator.process
            end.to change(Cartridge::ScoreDestination, :count).by(1)
            expect(Cartridge::ScoreDestination.last).to have_attributes(
              user_id: student.id,
              section: Section.last,
              activity: activity,
              lis_result_sourcedid: data[:lis_result_sourcedid]
            )
          end

          it 'does not create a line item destination' do
            expect do
              creator.process
            end.not_to change(Cartridge::LineItemDestination, :count)
          end

          it 'creates the enrollment' do
            expect do
              creator.process
            end.to change(Enrollment, :count).by(1)
            expect(Enrollment.last).to have_attributes(
              user_id: student.id,
              section: Section.last
            )
          end
        end
      end

      context 'when the launch is a CC 1.3 launch' do
        let(:data) { data_cc_1_3_0 }

        context 'when the resource link is an activity' do
          include_examples 'course, section and course context detail check'
        end

        context 'when the resource link is a resource' do
          let(:creator) { creator_with_resource }
          include_examples 'course, section and course context detail check'
        end

        context 'when the resource link is a vtext_link' do
          let(:creator) { creator_with_instructor_vtext_link }
          include_examples 'course, section and course context detail check'
        end

        context 'when the current user is an instructor' do
          include_examples 'instructor check'
        end

        context 'when the current user is a student' do
          let(:creator) { described_class.new(data, student, activity_resource_link) }

          it 'creates the line item destination' do
            expect do
              creator.process
            end.to change(Cartridge::LineItemDestination, :count).by(1)
            expect(Cartridge::LineItemDestination.last).to have_attributes(
              user_id: student.id,
              section: Section.last,
              activity: activity,
              line_item_url: data[:line_item_url]
            )
          end

          it 'does not create a score destination' do
            expect do
              creator.process
            end.not_to change(Cartridge::ScoreDestination, :count)
          end

          it 'creates the enrollment' do
            expect do
              creator.process
            end.to change(Enrollment, :count).by(1)
            expect(Enrollment.last).to have_attributes(
              user_id: student.id,
              section: Section.last
            )
          end

          context 'when checking whether to delay student enrollment' do
            before do
              allow(creator).to receive(:sleep)

              # This is not best practice, but is the easiest way to set up this test.
              allow_any_instance_of(Section).to receive(:created_at).and_return(created_at)
            end

            context 'when the section was just created' do
              let(:created_at) { 1.second.ago }

              it 'waits for the new section to sync to UA before creating the enrollment' do
                max_delay = Cartridge::CourseSectionCreator::MAX_SECONDS_TO_DELAY_ENROLLMENT
                Timecop.freeze(Time.current) do
                  wait_time = max_delay - (Time.current - created_at)

                  creator.process
                  expect(creator).to have_received(:sleep).with(wait_time)
                end
              end
            end

            context 'when the section existed before the student launch' do
              let(:created_at) { 4.seconds.ago }

              it 'does not wait before creating the enrollment' do
                creator.process
                expect(creator).not_to have_received(:sleep)
              end
            end
          end
        end
      end
    end

    context 'when the context id exists in the database,' do
      let!(:course) { create(:course, owner: contexts_owner, school: school) }
      let!(:section) { create(:section, course: course, instructor: contexts_owner) }
      let!(:category) { create(:category, course: course) }
      let!(:course_context_detail) do
        create(
          :cartridge_course_context_detail,
          section_id: section.id,
          course_id: course.id,
          lms_context_id: data[:context_id],
          school: school,
          program_id: program.id
        )
      end

      RSpec.shared_examples 'instructor check' do
        it 'creates a section instructor with role Co-instructor' do
          expect do
            creator.process
          end.to change(SectionInstructor, :count).by(1)
          expect(SectionInstructor.where(role: 'Co-instructor')).to contain_exactly(
            an_object_having_attributes(
              user_id: instructor.id,
              section: Section.last
            )
          )
        end
      end

      RSpec.shared_examples 'student check' do
        it 'does not create a section instructor' do
          creator = described_class.new(data, student, activity_resource_link)
          expect do
            creator.process
          end.not_to change(SectionInstructor, :count)
        end
      end

      include_examples 'instructor program access check'

      context 'when the launch is a legacy CC 1.1 launch' do
        context 'when the current user is an instructor' do
          include_examples 'instructor check'
        end

        context 'when the lis_outcome_service_url of an existing course context' \
        'detail record is nil and the lis_outcome_service_url is present' do
          it 'updates the lis_outcome_service_url' do
            course_context_detail.update(lis_outcome_service_url: nil)

            creator.process
            expect(course_context_detail.reload).to have_attributes(
              lis_outcome_service_url: data[:lis_outcome_service_url]
            )
          end
        end

        context 'when the lis_outcome_service_url of an existing course context' \
        'detail record is not nil and the lis_outcome_service_url is not present' do
          it 'does not update the lis_outcome_service_url' do
            data[:lis_outcome_service_url] = nil

            expect do
              creator.process
            end.not_to change(course_context_detail.reload, :lis_outcome_service_url)
          end
        end

        context 'when the lis_outcome_service_url of an existing course context' \
        'detail record and the lis_outcome_service_url are not nil but they are different' do
          it 'updates the lis_outcome_service_url' do
            new_url = 'www.newurl.com'
            data[:lis_outcome_service_url] = new_url

            creator.process
            expect(course_context_detail.reload).to have_attributes(
              lis_outcome_service_url: new_url
            )
          end
        end

        context 'when the current user is a student' do
          include_examples 'student check'
        end
      end

      context 'when the launch is a CC 1.3 launch' do
        let(:data) { data_cc_1_3_0 }

        context 'when the current user is an instructor' do
          include_examples 'instructor check'
        end

        context 'when the line_items_url of an existing course context' \
                'detail record is nil and the line_items_url is present' do
          it 'updates the line_items_url' do
            course_context_detail.update(line_items_url: nil)

            creator.process
            expect(course_context_detail.reload).to have_attributes(
              line_items_url: data[:line_items_url]
            )
          end
        end

        context 'when the line_items_url of an existing course context' \
                'detail record is not nil and the line_items_url is not present' do
          it 'does not update the line_items_url' do
            data[:line_items_url] = nil

            expect do
              creator.process
            end.not_to change(course_context_detail.reload, :line_items_url)
          end
        end

        context 'when the line_items_url of an existing course context' \
                'detail record and the line_items_url are not nil but they are different' do
          it 'updates the line_items_url' do
            new_url = 'www.newurl.com'
            data[:line_items_url] = new_url

            creator.process
            expect(course_context_detail.reload).to have_attributes(
              line_items_url: new_url
            )
          end
        end

        context 'when the current user is a student' do
          include_examples 'student check'
        end
      end
    end


    context 'when the context id exists in the database but for a different program' do
      let!(:different_program) { create(:program_with_lessons) }
      let!(:diff_activity) { create(:activity, lesson: different_program.lessons.first) }
      let!(:diff_activity_resource_link) { create(:cartridge_resource_link, resource_id: diff_activity.id) }
      let!(:diff_creator) { described_class.new(data, instructor, diff_activity_resource_link) }
      let!(:course) { create(:course, owner: contexts_owner, school: school, program: program) }
      let!(:section) { create(:section, course: course, instructor: contexts_owner) }
      let!(:category) { create(:category, course: course) }
      let!(:course_context_detail) do
        create(
          :cartridge_course_context_detail,
          section_id: section.id,
          course_id: course.id,
          lms_context_id: data[:context_id],
          school: school,
          program_id: program.id
        )
      end

      context 'when the resource link is an activity' do
        it 'creates the course, the section and the course context detail' do
          expect do
            diff_creator.process
          end.to change(Course, :count).by(1)
            .and change(Section, :count).by(1)
            .and change(Cartridge::CourseContextDetail, :count).by(1)
          expect(Course.last).to have_attributes(
            name: data[:context_title],
            owner_id: contexts_owner.id,
            program: different_program
          )
          expect(Section.last).to have_attributes(
            name: data[:context_title],
            instructor_id: contexts_owner.id,
            course: Course.last
          )
          expect(Cartridge::CourseContextDetail.last).to have_attributes(
            lms_context_id: data[:context_id],
            course: Course.last,
            section: Section.last,
            lis_outcome_service_url: data[:lis_outcome_service_url],
            school: school,
            program_id: different_program.id
          )
        end
      end

      it 'creates the section instructor with role instructor' do
        expect do
          diff_creator.process
        end.to change(SectionInstructor, :count).by(2)
        # there will already be SectionInstructor record for this instructor,
        # but for the section from the course in a different program
        expect(SectionInstructor.where(role: 'Instructor', section: Section.last)).to contain_exactly(
          an_object_having_attributes(
            user_id: contexts_owner.id,
            section: Section.last
          )
        )
      end

      it 'creates the section instructor with role Co-instructor if the' \
        'current user is an instructor' do
        expect do
          diff_creator.process
        end.to change(SectionInstructor, :count).by(2)
        expect(SectionInstructor.where(role: 'Co-instructor')).to contain_exactly(
          an_object_having_attributes(
            user_id: instructor.id,
            section: Section.last
          )
        )
      end

      context 'when the current user is a student' do
        let(:diff_creator) { described_class.new(data, student, diff_activity_resource_link) }

        it 'creates the score destination' do
          expect do
            diff_creator.process
          end.to change(Cartridge::ScoreDestination, :count).by(1)
          expect(Cartridge::ScoreDestination.last).to have_attributes(
            user_id: student.id,
            section: Section.last,
            activity: diff_activity,
            lis_result_sourcedid: data[:lis_result_sourcedid]
          )
        end

        it 'creates the enrollment' do
          expect do
            diff_creator.process
          end.to change(Enrollment, :count).by(1)
          expect(Enrollment.last).to have_attributes(
            user_id: student.id,
            section: Section.last
          )
        end
      end
    end

    context 'when the context id is for an archived course' do
      let(:course) { create(:closed_course, is_archived: true, program: program, school: school) }
      let(:section) { create(:section, is_archived: true, course: course) }

      before do
        create(
          :cartridge_course_context_detail,
          is_archived: true,
          course: course,
          section: section,
          lms_context_id: data[:context_id],
          school: school,
          program_id: program.id
        )
      end

      RSpec.shared_examples 'course and section checks' do
        it 'does not create a new course' do
          expect do
            creator.process
          end.not_to change(Course, :count)
        end

        it 'does not create a new section' do
          expect do
            creator.process
          end.not_to change(Section, :count)
        end

        it 'sets the closed course error' do
          expected_error = 'The course you are trying to access has been closed in VHLCentral' \
                          ' and is no longer available.'
          creator.process
          expect(creator.errors[:closed_course]).to eq expected_error
        end
      end

      context 'when the launch is a legacy CC 1.1 launch' do
        include_examples 'course and section checks'
      end

      context 'when the launch is a CC 1.3 launch' do
        let(:data) { data_cc_1_3_0 }

        include_examples 'course and section checks'
      end
    end

    context 'when the context id is for a non closed course' do
      let(:course) { create(:closed_course, is_archived: false, program: program, school: school) }
      let(:section) { create(:section, is_archived: true, course: course) }

      before do
        create(
          :cartridge_course_context_detail,
          is_archived: false,
          course: course,
          section: section,
          lms_context_id: data[:context_id],
          school: school,
          program_id: program.id
        )

        allow_any_instance_of(Course).to receive(:save).and_return(false)
      end

      context 'when the launch is a legacy CC 1.1 launch' do
        it 'sets an error other than a closed course error' do
          creator.process

          expect(creator.errors).to include(:course)
          expect(creator.errors).not_to include(:closed_course)
        end
      end

      context 'when the launch is a CC 1.3 launch' do
        let(:data) { data_cc_1_3_0 }

        it 'sets an error other than a closed course error' do
          creator.process

          expect(creator.errors).to include(:course)
          expect(creator.errors).not_to include(:closed_course)
        end
      end
    end
  end

  describe '#create_course_and_section' do
    context 'with valid params' do

      RSpec.shared_examples 'course, section, instructor and license checks' do
        it 'assigns a course name if the context title is nil' do
          data[:context_title] = nil
          creator.create_course_and_section
          expect(Course.last.name).to eq course_section_name
        end

        it 'creates a section' do
          expect do
            creator.create_course_and_section
          end.to change(Section, :count).by(1)
          expect(Section.last).to have_attributes(
            name: data[:context_title],
            instructor_id: contexts_owner.id
          )
        end

        it 'assigns a section name if the context title is nil' do
          data[:context_title] = nil
          creator.create_course_and_section
          expect(Section.last.name).to eq course_section_name
        end

        it 'creates a section with time_zone and due_time' do
          time_zone = 'Moscow'
          contexts_owner.update!(time_zone: time_zone)
          creator.create_course_and_section
          section = Section.last
          expect(section.time_zone).to eq time_zone
          expect(section.due_time.strftime('%H:%M:%S')).to eql '23:59:00'
        end

        it 'sets the time_zone to Eastern if the instructor has not set a timezone' do
          contexts_owner.update!(time_zone: nil)
          creator.create_course_and_section
          section = Section.last
          expect(section.time_zone).to eq 'Eastern Time (US & Canada)'
        end

        it 'creates a section instructor' do
          expect do
            creator.create_course_and_section
          end.to change(SectionInstructor, :count).by(1)
          expect(SectionInstructor.last).to have_attributes(
            user_id: contexts_owner.id,
            section: Section.last,
            role: 'Instructor'
          )
        end

        it 'creates a course context detail' do
          expect do
            creator.create_course_and_section
          end.to change(Cartridge::CourseContextDetail, :count).by(1)
          expect(Cartridge::CourseContextDetail.last).to have_attributes(
            lms_context_id: data[:context_id],
            lis_outcome_service_url: data[:lis_outcome_service_url],
            course: Course.last,
            section: Section.last,
            school_id: cartridge_contexts_owner.school_id,
            launch_presentation_return_url: data[:launch_presentation_return_url],
            line_items_url: data[:line_items_url]
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

      RSpec.shared_examples 'course creation before and after July' do
        it 'creates a course with end_date the current year when creation month is after July' do
          allow(Time).to receive(:now).and_return(start_date_before_july)
          expect do
            creator.create_course_and_section
          end.to change(Course, :count).by(1)
          expect(Course.last).to have_attributes(
            name: data[:context_title],
            owner_id: contexts_owner.id,
            program_id: program.id,
            start_date: start_date_before_july.to_date,
            end_date: end_date_before_july.to_date,
            school_id: cartridge_contexts_owner.school_id
          )
        end

        it 'creates a course with end_date the next year when creation month is before July' do
          allow(Time).to receive(:now).and_return(start_date_after_july)
          expect do
            creator.create_course_and_section
          end.to change(Course, :count).by(1)
          expect(Course.last).to have_attributes(
            name: data[:context_title],
            owner_id: contexts_owner.id,
            program_id: program.id,
            start_date: start_date_after_july.to_date,
            end_date: end_date_after_july.to_date,
            school_id: cartridge_contexts_owner.school_id
          )
        end
      end

      context 'when the launch is a legacy CC 1.1 launch' do
        include_examples 'course creation before and after July'
        include_examples 'course, section, instructor and license checks'

        it 'creates a course context detail even if the lis_outcome_service_url is nil' do
          data[:lis_outcome_service_url] = nil
          creator.create_course_and_section
          course_context_detail = Cartridge::CourseContextDetail.last
          expect(course_context_detail.lis_outcome_service_url).to be_nil
        end

        it 'creates a course context detail even if the launch_presentation_return_url is nil' do
          data[:launch_presentation_return_url] = nil
          creator.create_course_and_section
          course_context_detail = Cartridge::CourseContextDetail.last
          expect(course_context_detail.launch_presentation_return_url).to be_nil
        end
      end

      context 'when the launch is a CC 1.3 launch' do
        let(:data) { data_cc_1_3_0 }

        include_examples 'course creation before and after July'
        include_examples 'course, section, instructor and license checks'

        it 'creates a course context detail even if the line_items_url is nil' do
          data[:line_items_url] = nil
          creator.create_course_and_section
          course_context_detail = Cartridge::CourseContextDetail.last
          expect(course_context_detail.line_items_url).to be_nil
        end

        it 'creates a course context detail even if the launch_presentation_return_url is nil' do
          data[:line_items_url] = nil
          creator.create_course_and_section
          course_context_detail = Cartridge::CourseContextDetail.last
          expect(course_context_detail.line_items_url).to be_nil
        end
      end
    end

    context 'with invalid params' do
      context 'with missing data' do
        it 'builds an errors hash' do
          data[:context_id] = nil
          creator.create_course_and_section
          expected_error = "Section #{data[:context_title]} could not be created: " \
            'Cartridge course context detail lms context is required'
          expect(creator.errors[:section]).to include expected_error
        end
      end
    end
  end

  describe '#check_and_associate_co_instructor' do
    before do
      allow(Time).to receive(:now).and_return(start_date_before_july)
      creator.create_course_and_section
    end

    RSpec.shared_examples 'co-instructor checks' do
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

      it 'does not create new section instructor record when I am already a co-instructor of the ' \
         'section' do
        section = Section.find_by(instructor: contexts_owner)
        create(:section_co_instructor, instructor: instructor, section: section)
        creator.check_and_associate_co_instructor
        expect(section.section_instructors.reload).to contain_exactly(
          an_object_having_attributes(
            user_id: contexts_owner.id,
            section_id: Section.last.id,
            role: 'Instructor'
          ),
          an_object_having_attributes(
            user_id: instructor.id,
            section_id: Section.last.id,
            role: 'Co-instructor'
          )
        )
      end
    end

    context 'when the launch is a legacy CC 1.1 launch' do
      include_examples 'co-instructor checks'
    end

    context 'when the launch is a CC 1.3 launch' do
      let(:data) { data_cc_1_3_0 }
      include_examples 'co-instructor checks'
    end
  end

  describe '#create_or_update_score_destination' do
    context 'when the current user is a student' do
      let(:creator) { described_class.new(data, student, activity_resource_link) }

      before do
        allow(Time).to receive(:now).and_return(start_date_before_july)
      end

      RSpec.shared_examples 'assignment check' do
        it 'creates an assignment if there is none for this activity' do
          creator.create_course_and_section
          expect do
            creator.create_or_update_score_destination
          end.to change(Assignment, :count).by(1)
        end

        it 'does not create an assignment if there already is one for this activity' do
          assignment = create(:assignment, assignable: activity, due_date: start_date_before_july)
          allow(Assignment).to receive(:find_with_course_category).and_return(assignment)
          creator.create_course_and_section
          expect do
            creator.create_or_update_score_destination
          end.not_to change(Assignment, :count)
        end
      end

      context 'when the launch is a legacy CC 1.1 launch' do
        context 'when the resource link is an activity' do
          include_examples 'assignment check'

          it 'creates a score destination if the lis_outcome_service url and lis_result_sourcedid' \
             'are present in the params' do
            creator.create_course_and_section
            expect do
              creator.create_or_update_score_destination
            end.to change(Cartridge::ScoreDestination, :count).by(1)
            expect(Cartridge::ScoreDestination.last).to have_attributes(
              user_id: student.id,
              section: Section.last,
              activity: activity,
              lis_result_sourcedid: data[:lis_result_sourcedid]
            )
          end

          it 'does not create a score destination if the lis_outcome_service url is not present in the params' do
            data[:lis_outcome_service_url] = nil
            expect do
              creator.create_or_update_score_destination
            end.not_to change(Cartridge::ScoreDestination, :count)
          end

          it 'does not create a score destination if the lis_result_sourcedid is not present in the params' do
            data[:lis_result_sourcedid] = nil
            expect do
              creator.create_or_update_score_destination
            end.not_to change(Cartridge::ScoreDestination, :count)
          end
        end

        context 'when the resource link is a resource' do
          it 'does not create a score destination' do
            expect do
              creator_with_resource.create_or_update_score_destination
            end.not_to change(Cartridge::ScoreDestination, :count)
          end
        end

        context 'when the resource link is a vtext_link' do
          it 'does not create a score destination' do
            expect do
              creator_with_instructor_vtext_link.create_or_update_score_destination
            end.not_to change(Cartridge::ScoreDestination, :count)
          end
        end
      end

      context 'when the launch is a CC 1.3 launch' do
        let(:data) { data_cc_1_3_0 }

        context 'when the resource link is an activity' do
          include_examples 'assignment check'

          it 'creates a score destination if the lis_outcome_service url and lis_result_sourcedid' \
             'are present in the params' do
            creator.create_course_and_section
            expect do
              creator.create_or_update_score_destination
            end.to change(Cartridge::LineItemDestination, :count).by(1)
            expect(Cartridge::LineItemDestination.last).to have_attributes(
              user_id: student.id,
              section: Section.last,
              activity: activity,
              line_item_url: data[:line_item_url]
            )
          end

          it 'does not create a line item destination if the line_item_url is not present in ' \
            'the params' do
            data[:line_item_url] = nil
            expect do
              creator.create_or_update_score_destination
            end.not_to change(Cartridge::LineItemDestination, :count)
          end

          it 'does not create a line item destination if the line_item_url is not present in ' \
            'the params' do
            data[:line_item_url] = nil
            expect do
              creator.create_or_update_score_destination
            end.not_to change(Cartridge::LineItemDestination, :count)
          end
        end

        context 'when the resource link is a resource' do
          it 'does not create a line item destination' do
            expect do
              creator_with_resource.create_or_update_score_destination
            end.not_to change(Cartridge::LineItemDestination, :count)
          end
        end

        context 'when the resource link is a vtext_link' do
          it 'does not create a line item destination' do
            expect do
              creator_with_instructor_vtext_link.create_or_update_score_destination
            end.not_to change(Cartridge::LineItemDestination, :count)
          end
        end
      end
    end
  end

  describe '#student_enroller' do
    let(:course) { create(:course, owner: contexts_owner, school: school, program: program) }
    let(:section) { create(:section, course:course, instructor: contexts_owner) }

    before do
      create(:cartridge_course_context_detail,
             section_id: section.id,
             course_id: section.course.id,
             lms_context_id: data[:context_id],
             school: section.course.school,
             program_id: section.course.program.id)
    end

    RSpec.shared_context 'insufficient access' do
      let(:enroller) { instance_double(EnrollmentEngine::Enroller, errors: enroller_errors, warnings: {}) }
      let(:enroller_errors) { ActiveModel::Errors.new(nil) }

      before do
        allow(enroller).to receive(:enroll).and_return(enroller)
        allow(EnrollmentEngine::Enroller).to receive(:new).and_return(enroller)
      end
    end

    RSpec.shared_examples 'insufficient access checks' do
      it 'calls the enrollment engine if the enrollment exists but the student has insufficient access' do
        enrollment = create(:enrollment, section: section, user: student, sufficient_access: false)
        allow(Maestro::Enrollment).to receive(:check_licenses)
          .with([enrollment.guid])
          .and_return('enrollment_guids' => [enrollment.guid])

        creator.student_enroller

        expect(Maestro::Enrollment).to have_received(:check_licenses)
        expect(enrollment.reload.sufficient_access).to be_truthy
      end

      it 'ignores the insufficient access error from the enrollment' do
        expected_error = 'some other error'
        enroller_errors.add(:base, expected_error)
        enroller_errors.add(:base, Cartridge::CourseSectionCreator::ENROLLMENT_ERROR_TO_SKIP)
        creator.student_enroller
        expect(creator.errors[:enrollment]).to eq "Student guid: #{expected_error}"
      end
    end

    context 'when the launch is a legacy CC 1.1 launch' do
      context 'when the current user is a student' do
        let(:creator) { described_class.new(data, student, activity_resource_link) }

        it 'creates the enrollment of the student if the enrollment does not exist' do
          expect do
            creator.student_enroller
          end.to change(Enrollment, :count).by(1)
          expect(Enrollment.last).to have_attributes(
            user_id: student.id,
            section_id: section.id
          )
        end

        it 'does not create the enrollment if the enrollment exists' do
          create(:enrollment, section: section, user: student)

          expect do
            creator.student_enroller
          end.not_to change(Enrollment, :count)
        end

        context 'when there is insufficient access' do
          include_context 'insufficient access'
          include_examples 'insufficient access checks'
        end
      end

      context 'when the current user is an instructor' do
        it 'does not create the enrollment for an instructor' do
          creator = described_class.new(data, instructor, activity_resource_link)
          expect do
            creator.student_enroller
          end.not_to change(Enrollment, :count)
        end
      end
    end

    context 'when the launch is a CC 1.3 launch' do
      let(:data) { data_cc_1_3_0 }

      context 'when the current user is a student' do
        let(:creator) { described_class.new(data, student, activity_resource_link) }

        it 'creates the enrollment of the student if the enrollment does not exist' do
          expect do
            creator.student_enroller
          end.to change(Enrollment, :count).by(1)
          expect(Enrollment.last).to have_attributes(
            user_id: student.id,
            section_id: section.id
          )
        end

        it 'does not create the enrollment if the enrollment exists' do
          create(:enrollment, section: section, user: student)

          expect do
            creator.student_enroller
          end.not_to change(Enrollment, :count)
        end

        context 'when there is insufficient access' do
          include_context 'insufficient access'
          include_examples 'insufficient access checks'
        end
      end

      context 'when the current user is an instructor' do
        it 'does not create the enrollment for an instructor' do
          creator = described_class.new(data, instructor, activity_resource_link)
          expect do
            creator.student_enroller
          end.not_to change(Enrollment, :count)
        end
      end
    end
  end

  describe '#success' do
    let(:section) { create(:section) }

    before do
      allow(Maestro::CourseLicense).to receive(:all).and_return([])
      allow(creator).to receive(:existing_section).and_return(section)
    end

    it 'retries 20 times to contact the maestro_client api' do
      creator.success
      expect(Maestro::CourseLicense).to have_received(:all).exactly(20).times.with(section.course.guid)
    end

    it 'returns false if there are any errors' do
      creator.errors[:some_error] = 'something went wrong.'
      expect(creator.success).to be_falsey
    end

    it 'returns false if there is no section' do
      allow(creator).to receive(:existing_section).and_return(nil)
      expect(creator.success).to be_falsey
    end

    it 'returns false if there is an exception contacting the maestro_client api' do
      allow(Maestro::CourseLicense).to receive(:all).and_raise(MaestroCore::ConnectionError)
      expect(creator.success).to be_falsey
    end

    it 'adds an error that points that is something wrong with the course license if none are found' do
      expected_message = "The Course Licenses for #{section.course.name} have not been created."
      expect(creator.success).to be_falsey
      expect(creator.errors[:course_license]).to eq expected_message
    end

    it 'returns true if there are course licenses for the section course' do
      allow(Maestro::CourseLicense).to receive(:all).and_return([instance_double(Maestro::CourseLicense)])
      expect(creator.success).to be_truthy
    end
  end
end
