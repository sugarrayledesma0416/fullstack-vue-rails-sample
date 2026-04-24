# encoding: utf-8

feature 'Course Focus Selector' do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:school) { create(:school) }
  let(:instructor) { create(:instructor, schools: [school]) }
  let(:program) { create(:program) }
  let(:course_licenses) { Array.new }
  let(:activity) {  create_activity_with_unit_lesson_and_concept(program) }

  before do
    give_instructor_access_to_toc
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  scenario 'Instructor does not see the focus selector if has no courses' do
    visit instructor_toc_path(program)
    expect(page).not_to have_selector('.masthead_focus')
  end

  scenario 'Instructor with closed courses see the text: no courses selected' do
    closed_course = create(:closed_course, :owner => instructor, :program => program)
    visit instructor_toc_path(program)
    expect(page).to have_selector('.focus_indicator_no_course', text: 'No course selected')
  end

  scenario 'Instructor with closed courses focused on an active one can see a link to view old courses' do
    closed_course = create(:closed_course, :owner => instructor, :program => program)
    visit instructor_toc_path(program)
    expect(find(".focus_show_other_courses")).to have_link('Show older courses')
  end

  scenario 'If focused on an active course then selector shows active courses' do
    open_course = create(:open_course, :owner => instructor, :program => program)
    another_open_course = create(:open_course, :owner => instructor, :program => program)
    visit instructor_toc_path(program)
    find("#js_course_#{open_course.id}").click
    expect(page).to have_selector("#js_course_#{another_open_course.id}")
  end

  scenario 'If focused on an active course then I should see a link to view old courses' do
    open_course = create(:open_course, :owner => instructor, :program => program)
    visit instructor_toc_path(program)
    find("#js_course_#{open_course.id}").click
    expect(find(".focus_show_other_courses")).to have_link('Show older courses')
  end

end
