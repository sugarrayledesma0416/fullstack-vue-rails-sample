feature 'Upload File Assessment', chrome: true, js: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course) do
    create(
      :course,
      owner: instructor,
      program: program,
      chat_level: 'disabled'
    )
  end
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:category) { create(:category, course: course, penalty_percent: 0) }
  let!(:activity) do
    create_activity_with_unit_lesson_concept_strand_and_substrand(
      program,
      instructor_revision_id: 70
    )
  end
  let(:assessment) do
    create(
      :instructor_created_activity,
      lesson: lesson,
      toc_location: strand.location,
      concept: concept,
      cms_revision_id: 1
    )
  end

  let(:audio_media_item) { create(:media_item_audio, filename: 'vocab_list_audio_1.mp3') }

  let(:audio_media_link) { MediaLink.new(desired_media_item_id: audio_media_item.id) }

  let(:exam_content_object) do
    MaestroActivityEngine::ActivityContent::ExamContent.new
  end
  let(:upload_file_content_object) do
    MaestroActivityEngine::ActivityContent::UploadFileActivityContent.new
  end
  let(:upload_file_item) do
    MaestroActivityEngine::ActivityContent::UploadFileActivity::Item.new(rank: 1)
  end
  let(:exam_reference) do
    MaestroActivityEngine::ActivityContent::Reference::Exam.new(rank: 1)
  end

  def add_title_and_dl_to_exam_reference()
    exam_reference.header = Nokogiri::XML.parse('<body>sample title</body>').children.first
    exam_reference.body = Nokogiri::XML.parse('<body>sample direction line</body>').children.first
    exam_reference.header_audio = audio_media_link
    exam_reference.body_audio = audio_media_link
  end


  before do
    upload_file_item.file_path = 'https://dummy-url.com/dummy.pdf'
    upload_file_item.file_name = 'dummy.pdf'
    upload_file_item.points_possible = 1
    exam_content_object.activities = [upload_file_content_object]
    upload_file_content_object.items.push(upload_file_item)
    add_title_and_dl_to_exam_reference
    upload_file_content_object.items.push(exam_reference)
    exam_content_object.language = 'es'
    allow_any_instance_of(
      Activity
    ).to receive(:content_object).and_return(exam_content_object)
  end

  def validate_upload_file_activity_content
    step 'I can see the activity title' do
      expect(page).to have_selector(
        '.test-reference-diagnostic-header',
        text: 'sample title'
      )
    end

    step 'I can see the audio icon for the activity title' do
      expect(page).to have_selector('.test-play-header-audio')
    end

    step 'I can see the audio icon for the activity direction line' do
      expect(page).to have_selector('.test-play-body-audio')
    end

    step 'I can see the file name link' do
      expect(page).to have_selector(
        '.test-file-name-link',
        text: 'dummy.pdf'
      )
    end

    step 'Click on file name link' do
      find('.test-file-name-link').click
    end

    validate_upload_file_warning_dialog
  end

  def validate_upload_file_warning_dialog
    step 'I can see a dialog with message "Vista Higher Learning is not responsible' \
    ' for any content downloaded using this link."' do
      expect(page).to have_selector(
        '.test-dialog-panel',
        text: 'Vista Higher Learning is not responsible for any content downloaded' \
        ' using this link.',
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
        text: 'Vista Higher Learning is not responsible for any content on any ' \
        'linked site.',
        visible: true
      )
    end
  end

  scenario 'As a student, I can view the assessment with upload file activity ' \
    'in preview mode' do
    create(:enrollment, user: student, section: section)
    create(
      :assignment,
      assignable: activity,
      category: category,
      due_date: Date.tomorrow,
      section: section
    )

    give_user_access_to_program(student, program)
    log_in_as(student)
    visit section_activity_path(section_id: section.id, id: activity.id)
    validate_upload_file_activity_content

    step 'I can see the submit button enabled' do
      expect(page).to have_button('Submit', disabled: false)
    end
  end

  scenario 'As a student, I can view the assessment with upload file activity ' \
    'in practice mode' do
    create(:enrollment, user: student, section: section)
    create(
      :assignment,
      assignable: activity,
      category: category,
      due_date: Date.tomorrow,
      section: section
    )
    create(:attempt_completed, activity: activity, section: section, user: student)

    give_user_access_to_program(student, program)
    log_in_as(student)

    visit practice_section_activity_path(section_id: section.id, id: activity.id)
    validate_upload_file_activity_content

    step 'I can see score "1 of 1 pts. 100.0%"' do
      expect(page).to have_selector(
        '.test-footer-score-content',
        text: '1 of 1 pts. 100.0%',
        visible: true
      )
    end

    step 'I cannot see the "Submit" button' do
      expect(page).to have_no_button('Submit')
    end
  end
end
