feature 'visit an activity in canvas', js: true, chrome: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers

  let(:instructor) { create(:cartridge_instructor) }
  let(:student) { create(:cartridge_student) }
  let(:school) { create(:school) }
  let(:program) { create(:program_with_lessons) }
  let(:activity) { create_fill_in_the_blanks_activity_with_model(program) }
  let(:course) { create(:closed_course, is_archived: true, program: program, school: school) }
  let(:section) { create(:section, is_archived: true, course: course) }
  let(:resource_link) { create(:cartridge_resource_link, resource_id: activity.id, program: program) }
  let(:course_context_detail) do
    create(:cartridge_course_context_detail,
           is_archived: true,
           course: course,
           section: section,
           school: school,
           program_id: program.id
    )
  end
  let(:consumer) { create(:cartridge_consumer, school: school) }
  let(:default_params) do
    {
      resource_link_id: resource_link.resource_link_id,
      consumer_guid: consumer.guid,
      context_id: course_context_detail.lms_context_id,
      context_label: 'Context label',
      context_title: 'Context title',
      launch_presentation_return_url: 'www.lms.com',
      lis_outcome_service_url: 'MyLisOutcomeServiceUrl',
      lis_result_sourcedid: SecureRandom.uuid,
      lti_version: '1.1.0'
    }
  end

  before do
    create(:school_user, user: instructor, school: school)
    create(:school_user, user: student, school: school)
    create(:active_enrollment, user: student, section: section)
    create(:cartridge_instructor_user_link, user: instructor, school: school)
    create(:cartridge_student_user_link, user: student, school: school)
    allow(HTTP_AUTHENTICATIONS).to receive(:values).and_return(%w[secret1])
  end

  def encode_params(params)
    { launch_params: (JWT.encode params, 'secret1', 'HS256') }
  end

  scenario 'an instructor is going to check an activity in an archived course' do
    purpose 'the instructor will see a view saying that the course is closed' do
      step 'login as a cartridge instructor' do
        log_in_as(instructor)
        give_user_access_to_program(instructor, program)
      end

      step 'visit an activity' do
        visit cartridge_launch_path(
          resource_link.resource_link_id,
          params: encode_params(default_params)
        )

        expect(page).to have_selector('.test-cartridge-access-denied')
        expect(page).to have_content('The course you are trying to access has been closed in' \
                                     ' VHLCentral and is no longer available.')
      end
    end
  end

  scenario 'an student is going to check an activity in an archived course' do
    purpose 'the student will see a view saying that the course is closed' do
      step 'login as a cartridge instructor' do
        log_in_as(student)
        give_user_access_to_program(student, program)
      end

      step 'visit an activity' do
        visit cartridge_launch_path(
          resource_link.resource_link_id,
          params: encode_params(default_params)
        )

        expect(page).to have_selector(
          '.test-cartridge-access-denied',
          text: 'The course you are trying to access has been closed in VHLCentral' \
                ' and is no longer available.'
        )
      end
    end
  end
end
