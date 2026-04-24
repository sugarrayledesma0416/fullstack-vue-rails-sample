feature 'External Link Assessment', chrome: true, js: true do
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

  let(:exam_content_object) do
    MaestroActivityEngine::ActivityContent::ExamContent.new
  end
  let(:external_link_content_object) do
    MaestroActivityEngine::ActivityContent::ExternalLinkContent.new
  end
  let(:external_link_item) do
    MaestroActivityEngine::ActivityContent::ExternalLink::Item.new(rank: 1)
  end

  before do
    external_link_item.external_link_url = 'https://dummy-url-1.com/'
    external_link_item.points_possible = 1
    exam_content_object.activities = [external_link_content_object]
    external_link_content_object.items.push(external_link_item)
    exam_content_object.language = 'es'
    allow_any_instance_of(
      Activity
    ).to receive(:content_object).and_return(exam_content_object)
  end

  def validate_external_link_activity_content
    step 'I can see the external link url' do
      expect(page).to have_selector(
        '.test-external-link-url',
        text: 'https://dummy-url-1.com/'
      )
    end

    step 'Click on external link url' do
      find('.test-external-link-url').click
    end

    validate_external_link_warning_dialog
  end

  def validate_external_link_warning_dialog
    step 'I can see a dialog with message "Vista Higher Learning is not responsible ' \
      'for any content on any linked site."' do
      expect(page).to have_selector(
        '.test-dialog-panel',
        text: 'Vista Higher Learning is not responsible for any content on any ' \
        'linked site.',
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

  scenario 'As a student, I can view the assessment with external link activity ' \
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

    validate_external_link_activity_content

    step 'I can see the submit button enabled' do
      expect(page).to have_button('Submit', disabled: false)
    end
  end

  scenario 'As a student, I can view the assessment with external link activity ' \
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

    validate_external_link_activity_content

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
