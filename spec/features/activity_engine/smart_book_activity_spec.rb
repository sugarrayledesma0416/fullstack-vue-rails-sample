feature 'Smart book activity', test_debt: true, js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include ActivityTest::MockSubmissions
  include Capybara::Angular::DSL
  include ActivityTest::Helpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:activity) { create_smart_book_activity(program) }
  let(:activity_data) { ActivityTest::ActivityData::SantillanaBook.new(activity) }
  let(:fake_submissions) { {} }

  before do
    allow(Xapi::ActivityState).to receive(:find).and_return(nil)
  end

  context 'as a student' do
    before do
      initialize_fake_submissions_client
      give_user_access_to_program(student, program)
      log_in_as(student)
      create(:active_enrollment, section: section, user: student)
    end

    scenario 'I can do a smart book activity' do
      visit section_activity_path(section.id, activity)
      for_santillana_book_page(activity_data) do
        expect_activity_shell_structure_to_be_complete
        expect(@page_object).to have_no_attempts
      end
      # When leaving the smartbook activity page, the page sends a
      # statement write request that can be received after the database cleanup.
      # To ensure this does not occur, we visit another page before ending the spec.
      visit course_section_path(course, section)
    end
  end
end
