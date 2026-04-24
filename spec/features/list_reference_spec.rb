feature 'List Reference', chrome: true, js: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program) }
  let(:assessment_strand) { create(:toc_entry) }
  let(:course) do
    create(:course,
            owner: instructor,
            program:,
            allows_help_requests: true,
            allows_review_requests: true)
  end
  let(:section) { create(:section, course:, instructor:) }
  let(:unit) { create(:unit, program:) }
  let(:lesson) { create(:lesson, toc_entries: [assessment_strand], unit:) }
  let(:activity) do
    create(:json_activity_with_list, title: 'Mid-Unit Assessment', lesson:)
  end
  let(:category) { create(:category, course:, penalty_percent: 0) }

  def validate_list_reference
    step 'I can see list reference header' do
      expect(page).to have_selector(
        '.reference_list > h3 > header',
        text: 'List title'
      )
    end

    step 'I can see list reference body' do
      within('.reference_list') do
        expect(page).to have_selector('li', text: 'Item 1')
        expect(page).to have_selector('li', text: 'Item 2')
      end
    end
  end

  scenario 'As a student, I can view the assessment with list reference ' \
        'in preview mode' do
    create(:enrollment, user: student, section: section)
    create(
    :assignment,
    assignable: activity,
    category:,
    due_date: Date.tomorrow,
    section:
    )

    give_user_access_to_program(student, program)
    log_in_as(student)
    visit section_activity_path(section_id: section.id, id: activity.id)
    validate_list_reference
  end
end
