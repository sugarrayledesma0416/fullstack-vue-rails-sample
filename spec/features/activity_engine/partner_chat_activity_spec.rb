feature 'Partner Chat Activity', chrome: true, js: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include ActivityTest::Helpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }

  let(:course) do
    create(
      :course,
      owner: instructor,
      program:,
      allows_help_requests: true
    )
  end

  let(:section) { create(:section, course:, instructor:) }
  let(:content_object) do
    MaestroActivityEngine::ActivityContent::PartnerChatContent.new
  end

  let(:item) { MaestroActivityEngine::ActivityContent::PartnerChat::Item.new }

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
      content_object.items.push(item)
      content_object.language = 'es'
      allow_any_instance_of(
        Activity
      ).to receive(:content_object).and_return(content_object)

      initialize_fake_submissions_client
      give_user_access_to_program(student, program)
      log_in_as(student)
      create(:active_enrollment, section:, user: student)
    end

    scenario 'I can view the partner chat activity content' do
      visit section_activity_path(section.id, activity)

      step 'I can see a chat widget' do
        expect(page).to have_selector('.test-chat-widget')
      end

      step 'I can see the "Go to Dashboard" button' do
        expect(page).to have_link('Go to Dashboard', href: student_dashboard_url)
      end
    end
  end
end
