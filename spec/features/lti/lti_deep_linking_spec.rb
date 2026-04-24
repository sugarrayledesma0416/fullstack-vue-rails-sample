feature 'Lti Deep Linking', chrome: true, js: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers

  let(:claims) { GradebookEngine::Lti::Constants::CLAIMS }
  let(:platform) { create(:lti_platform) }
  let(:private_key) { Rails.configuration.lti_tool_private_keys.first }
  let(:public_key) { private_key.public_key }
  let(:instructor) { create(:instructor) }
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

  xscenario 'As an instructor, I can create a deep link to an assessment' do
    quiz_1 = create_assessment_with_unit_lesson_concept(program)
    quiz_2 = create_assessment_with_unit_lesson_concept(
      program,
      strand_id: quiz_1.toc_location
    )
    launch = create(
      :lti_launch,
      platform:
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

      expect(page).to have_link('Link to a Specific Assessment')

      click_link('Link to a Specific Assessment')

      expect(page).to have_selector(modal_test_class, visible: :hidden)

      within(quiz_1_test_class) do
        expect(page).to have_selector(
          "[data-js-activity-id='#{quiz_1.id}']",
          text: deep_link_control_label
        )
      end

      within(quiz_2_test_class) do
        expect(page).to have_selector(
          "[data-js-activity-id='#{quiz_2.id}']",
          text: deep_link_control_label
        )
      end

      within(quiz_1_test_class) do
        click_link(deep_link_control_label)
      end

      expect(page).to have_selector(modal_test_class, visible: :visible)

      within(modal_test_class) do
        expect(page).to have_selector(
          modal_header_class,
          text: modal_header_text
        )
        expect(page).to have_selector(
          activity_label_class,
          text: quiz_1.title
        )

        jwt = page.find(jwt_selector).value
        result = JWT.decode(jwt, public_key, true, algorithm: 'RS256').first

        expect(result['iss']).to eq(platform.client_id)
        expect(result['aud']).to eq(platform.issuer_id)
        expect(result[claims[:message_type]]).to eq(resource_message_type)
        expect(result[claims[:content_item]]).to contain_exactly(
          hash_including(
            'custom' => {
              'activity_id' => quiz_1.id, 'program_id' => program.id
            }
          )
        )
      end
    end
  end

  scenario 'As an instructor, I can create a deep link to an activity' do
    activity_1 = create_activity_with_unit_lesson_and_concept(program)
    activity_2 = create_activity_with_unit_lesson_and_concept(
      program,
      strand_id: activity_1.toc_location
    )
    launch = create(
      :lti_launch,
      platform:
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

      expect(page).to have_link('Link to a Specific Activity')

      click_link('Link to a Specific Activity')

      expect(page).to have_selector(modal_test_class, visible: :hidden)

      within(activity_1_test_class) do
        expect(page).to have_selector(
          "[data-js-activity-id='#{activity_1.id}']",
          text: deep_link_control_label
        )
      end

      within(activity_2_test_class) do
        expect(page).to have_selector(
          "[data-js-activity-id='#{activity_2.id}']",
          text: deep_link_control_label
        )
      end

      within(activity_1_test_class) do
        click_link(deep_link_control_label)
      end

      expect(page).to have_selector(modal_test_class, visible: :visible)

      within(modal_test_class) do
        expect(page).to have_selector(
          modal_header_class,
          text: modal_header_text
        )
        expect(page).to have_selector(
          activity_label_class,
          text: activity_1.title
        )

        jwt = page.find(jwt_selector).value
        result = JWT.decode(jwt, public_key, true, algorithm: 'RS256').first

        expect(result['iss']).to eq(platform.client_id)
        expect(result['aud']).to eq(platform.issuer_id)
        expect(result[claims[:message_type]]).to eq(resource_message_type)
        expect(result[claims[:content_item]]).to contain_exactly(
          hash_including(
            'custom' => {
              'activity_id' => activity_1.id, 'program_id' => program.id
            }
          )
        )
      end
    end
  end
end
