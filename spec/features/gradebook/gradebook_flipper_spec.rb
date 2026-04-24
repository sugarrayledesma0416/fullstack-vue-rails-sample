feature 'gradebook_analytics_flipper',
  js:true, chrome: true, new_gb_sync: true do

  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers

  let(:instructor) { create(:instructor) }
  let(:student_1) { create(:student) }
  let(:student_2) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:lesson) { program.units.first.lessons.first }
  let(:course) do
    create(
      :course,
      first_unit_id: program.units.first.id,
      last_unit_id: program.units.last.id,
      owner: instructor,
      program: program
    )
  end
  let!(:category) { create(:category, course: course) }
  let(:section) { create(:section, course: course, instructor: instructor) }

  before do
    allow(Rails.application.config).to receive(:enable_analytics).and_return(false)
    create(:gradebook_analytics_school, school_id: course.school_id)
    create(:enrollment, user: student_1, section: section)
    create(:enrollment, user: student_2, section: section)
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  scenario 'If the school has access to gradebook analytics' do
    visit gradebook_engine.course_section_scores_path(program_id: program.id,
                                                      course_id: course.id,
                                                      section_id: section.id)
    expect(page).to have_content('ANALYTICS')
  end
end
