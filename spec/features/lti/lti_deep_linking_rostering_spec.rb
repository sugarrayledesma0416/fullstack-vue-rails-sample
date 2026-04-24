feature 'Lti Deep Linking Rostering', chrome: true, js: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers

  let(:claims) { GradebookEngine::Lti::Constants::CLAIMS }
  let(:platform) { create(:lti_rostering_platform) }
  let(:private_key) { Rails.configuration.lti_tool_private_keys.first }
  let(:public_key) { private_key.public_key }
  let(:instructor) { create(:lti_rostering_instructor) }
  let!(:lti_user_link) { create(:lti_rostering_user_link, user: instructor, lti_platform: platform) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let!(:section) { create(:section, course: course, instructor: instructor) }

  let(:activity_class_prefix) { '.test-deep-link-activity-' }
  let(:activity_label_class) { '.test-deep-link-activity-label' }
  let(:deep_link_control_label) { 'LINK' }
  let(:jwt_selector) { 'input[name="JWT"]' }
  let(:modal_header_class) { '.test-deep-link-modal-header' }
  let(:modal_header_text) { 'Create Link' }
  let(:modal_test_class) { '.test-deep-link-modal' }
  let(:resource_message_type) { 'LtiDeepLinkingResponse' }

  let(:course_license) do
    Maestro::CourseLicense.new('license_group' => { 'id' => 1, 'demo' => false })
  end

  before do
    create_activity_with_unit_lesson_and_concept(program)
    initialize_program_access_client_calls_for_instructor(instructor, program)
    allow(Maestro::CourseLicense).to receive(:all).and_return([course_license])
    log_in_as(instructor)
  end

  scenario 'As an lti_rostering instructor, I can create a deep link to an assessment' do
    quiz_1 = create_assessment_with_unit_lesson_concept(program)
    quiz_2 = create_assessment_with_unit_lesson_concept(
      program,
      strand_id: quiz_1.toc_location
    )
    launch = create(
      :lti_launch,
      decoded_jwt: { 'aud' => platform.client_id, 'iss' => platform.issuer_id }
    )

    quiz_1_test_class = "#{activity_class_prefix}#{quiz_1.id}"
    quiz_2_test_class = "#{activity_class_prefix}#{quiz_2.id}"

    purpose 'I should not see deep linking controls when viewing the ' \
            'assessment toc without a deep link session' do
      visit instructor_assessments_path(program_id: program)
      expect(page).to have_no_selector(modal_test_class, visible: :hidden)
      expect(page).to have_no_selector(quiz_1_test_class)
    end

    purpose 'I should see deep linking controls when viewing the assessment ' \
            'toc with a deep link session' do
      visit lti_deep_link_session_init_path(
        launch_guid: launch.guid,
        program_id: program.id,
        section_guid: section.guid
      )
      expect(page).to have_button('Link to a Specific Assessment', disabled: false)
    end
  end

  scenario 'As an lti_rostering instructor, I can create a deep link to an activity' do
    activity_1 = create_activity_with_unit_lesson_and_concept(program)
    activity_2 = create_activity_with_unit_lesson_and_concept(
      program,
      strand_id: activity_1.toc_location
    )
    launch = create(
      :lti_launch,
      decoded_jwt: { 'aud' => platform.client_id, 'iss' => platform.issuer_id }
    )

    activity_1_test_class = "#{activity_class_prefix}#{activity_1.id}"
    activity_2_test_class = "#{activity_class_prefix}#{activity_2.id}"

    purpose 'I should not see deep linking controls when viewing the ' \
            'toc without a deep link session' do
      visit instructor_toc_path(program_id: program)
      expect(page).to have_no_selector(modal_test_class, visible: :hidden)
      expect(page).to have_no_selector(activity_1_test_class)
    end

    purpose 'I should see deep linking controls when viewing the toc ' \
            'with a deep link session' do
      visit lti_deep_link_session_init_path(
        launch_guid: launch.guid,
        program_id: program.id,
        section_guid: section.guid
      )

      expect(page).to have_button('Link to a Specific Activity', disabled: false)
    end
  end
end
