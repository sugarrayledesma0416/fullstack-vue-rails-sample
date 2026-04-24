feature 'Upload File Activity', js: true, chrome: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include Capybara::Angular::DSL
  include ActivityTest::Helpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }

  let(:course) do
    create(
      :course,
      owner: instructor,
      program: program,
      allows_help_requests: true,
    )
  end

  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:content_object) do
    MaestroActivityEngine::ActivityContent::UploadFileActivityContent.new
  end

  let(:item) { MaestroActivityEngine::ActivityContent::UploadFileActivity::Item.new }

  let!(:activity) do
    create_activity_with_unit_lesson_concept_strand_and_substrand(
      program,
      instructor_revision_id: 70
    )
  end

  def student_dashboard_url
    course_section_path(course, section)
  end

  context 'when logged in as student' do
    before do
      item.file_path = 'https://dummy-url.com/dummy.pdf'
      item.file_name = 'dummy.pdf'
      content_object.items.push(item)
      content_object.language = 'es'
      allow_any_instance_of(
        Activity
      ).to receive(:content_object).and_return(content_object)

      initialize_fake_submissions_client
      give_user_access_to_program(student, program)
      log_in_as(student)
      create(:active_enrollment, section: section, user: student)
    end

    scenario 'I can add help requests', nondeterministic: true do
      ignoring_angular do
        direction_line_help_request_comment = 'request help on the direction line'

        visit section_activity_path(section.id, activity)
        for_preview_page({}) do
          # Add an help request on the direction line and on a question
          {
            from_direction_line => direction_line_help_request_comment
          }.each do |item, item_comment|
            # insert 2 comments. The first one is a temporary one, it will be deleted
            comments = ['some temporary comment', item_comment]
            comments.each do |comment|
              validate_adding_instructor_help_request(
                item: item,
                comment: comment,
                helpable: [from_direction_line],
                non_helpable: []
              )
            end
            expect_help_request_to_be_displayed(
              item: item, request_number: 1, comment: comments[0]
            )
            expect_help_request_to_be_displayed(
              item: item, request_number: 2, comment: comments[1]
            )
            remove_help_request(item: item, request_number: 1)
            expect_help_request_to_be_displayed(
              item: item, request_number: 1, comment: comments[1]
            )
          end
        end
      end
    end

    scenario 'I can view the upload file name linkivity content' do
      visit section_activity_path(section.id, activity)

      step 'I can see the file name link' do
        expect(page).to have_selector(
          '.test-file-name-link',
          text: 'dummy.pdf'
        )
      end

      step 'Click on file name link' do
        find('.test-file-name-link').click
      end

      step 'I can see a dialog with message "Vista Higher Learning is not responsible ' \
        'for any content downloaded using this link."' do
        expect(page).to have_selector(
          '.test-dialog-panel',
          text: 'Vista Higher Learning is not responsible for any content downloaded ' \
          'using this link.',
          visible: true
        )
      end

      step 'I can see a button "AGREE AND CONTINUE" on the dialog' do
        expect(page).to have_selector(
          '.test-confirm-warning-btn',
          text: 'AGREE AND CONTINUE',
          visible: true
        )
      end

      step 'Click on "Cancel" to cancel the dialog' do
        find('.test-cancel-warning-btn', text: 'Cancel').click
      end

      step 'I cannot see the warning dialog' do
        expect(page).not_to have_selector(
          '.test-dialog-panel',
          text: 'Vista Higher Learning is not responsible for any content downloaded ' \
          'using this link.',
          visible: true
        )
      end

      step 'I can see the "Go to Dashboard" button' do
        expect(page).to have_link('Go to Dashboard', href: student_dashboard_url)
      end
    end
  end
end
