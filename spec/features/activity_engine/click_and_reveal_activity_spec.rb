feature 'Click and Reveal activity', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }
  let(:section) { create(:section, course: course, instructor: instructor) }

  let(:course) do
    create(:course, owner: instructor, program: program)
  end

  # ID is needed here because is specified in fixture file.
  let!(:media_items) do
    Array.new(4) do |i|
      id = i + 1
      create(:media_item_image, id: id, filename: "multiple_choice_prompt_#{id}.gif")
    end
  end

  let(:activity) { create_click_and_reveal_activity(program) }

  context 'with a student' do
    before do
      give_user_access_to_program(student, program)
      log_in_as(student)
      create(:active_enrollment, section: section, user: student)
    end

    scenario 'I can do a click and reveal activity' do
      visit section_activity_path(section.id, activity)

      within('.test-pair-1-tile-1') do
        expect(page).to have_selector(
          "img[src*='#{media_items[0].public_filename}']"
        )
      end
      expect(page).to have_selector('.test-pair-1-tile-2', text: 'choice1')

      within('.test-pair-2-tile-1') do
        expect(page).to have_selector(
          "img[src*='#{media_items[1].public_filename}']"
        )
      end
      expect(page).to have_selector('.test-pair-2-tile-2', text: 'choice2')
    end
  end
end
