feature 'Grading Quick-grade feature',
        chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers
  include WaitForNextPage

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
    create(:enrollment, user: student_1, section: section)
    create(:enrollment, user: student_2, section: section)
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  scenario 'As an instructor, when I quick-grade students who submitted an ' \
           'instructor-graded activity, they no longer show up as needing ' \
           'to be graded' do
    activity = create_open_ended_assessment(program)
    create(
      :attempt_completed,
      activity: activity,
      section: section,
      user: student_1
    )
    allow_any_instance_of(Attempt).to receive(:results) do
      MaestroActivityEngine::ActivityContent::Results
        .new(activity.content_object).tap do |results|
        results.add(label: 'question_01', response: '')
        results.add(label: 'question_02', response: '')
        results.add(label: 'question_03', response: '')
        results.add(label: 'question_04', response: '')
      end
    end
    create(
      :assignment,
      assignable: activity,
      category: category,
      due_date: 2.days.ago,
      section: section
    )
    create_gradebook_engine_submission(
      activity: activity,
      pending: true,
      student: student_1,
      submitted_at: 2.days.ago
    )

    visit instructor_grading_tasks_assignments_path(program.id)

    # The sub-section for upcoming grading should show 1 activity that needs
    # to be graded.
    expect(find('#needs_grading_section_to_grade.circled')).to have_text('1')

    # The submitted activity title should show up under needs grading.
    click_link('Needs grading')
    grading_list_item = find('.activity_grading')
    expect(grading_list_item).to have_link(activity.title)
    to_be_graded_count = grading_list_item.find('.graded')
    expect(to_be_graded_count.text).to eq('1 to be graded')

    # Use quick grade to grade the activities.
    visit activities_for_lesson_url

    column_header(activity).click
    header_menu(activity).find('a', text: 'Quick Grade (100%)').click

    find('label', text: 'Select all/none').click
    click_button('Grade')

    # There should no longer be any activities to be graded, in either
    # needs grading or upcoming sub-sections.
    wait_for_next_page do
      visit instructor_grading_tasks_assignments_path(program.id)
    end

    expect(find('#upcoming_grading_section_to_grade.circled')).to have_text('0')
    expect(find('#needs_grading_section_to_grade.circled')).to have_text('0')
    expect(find('#already_graded_section_to_grade.circled')).to have_text('1')
  end
end
