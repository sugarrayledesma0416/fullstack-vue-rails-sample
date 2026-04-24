def create_static_book_activity(program)
  create_activity_with_content(
    File.join('spec', 'fixtures', 'xml', 'static_book.xml'),
    program,
    grading_method: 'auto'
  )
end

feature 'Static book activity', test_debt: true, js: true, chrome: true do
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
  let(:activity) { create_static_book_activity(program) }
  let(:activity_data) { ActivityTest::ActivityData::SantillanaBook.new(activity) }

  context 'as a student' do
    before do
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
    end
  end
end
