feature 'Reviewing Score Review',
        chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:category) { create(:category, course: course) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:activity) { create_multiple_choice_activity(program) }

  let(:concept) { activity.concept }
  let(:lesson) { activity.lesson }
  let(:strand) { activity.strand }

  let(:attempt_results) do
    # The student answered the first question.
    MaestroActivityEngine::ActivityContent::Results
      .new(activity.content_object).tap do |results|
      results.add(label: 'question_01', response: '0')
      results.add(label: 'question_02', response: '')
      results.add(label: 'question_03', response: '')
      results.add(label: 'question_04', response: '')
    end
  end

  before do
    create(:enrollment, user: student, section: section)
    create(
      :assignment,
      assignable: activity,
      category: category,
      due_date: Date.yesterday,
      section: section
    )
    create(:attempt_completed, activity: activity, section: section, user: student)
    create(
      :review_request,
      activity: activity,
      activity_state: 'review',
      helpable_item_type: 'whole_question',
      helpable_item_id: 'question_01_whole_question',
      program: program,
      section_id: section.id,
      user: student
    )
    create_gradebook_engine_submission(submitted_at: Time.now.utc)
    allow_any_instance_of(Attempt).to receive(:results) { attempt_results }
    initialize_program_access_client_calls_for_instructor(instructor, program)
  end

  scenario 'As an instructor I can review a score review request created ' \
             'by a student' do
    log_in_as(instructor)
    visit(instructor_help_requests_path(program.id))

    # Expand the section for pending review requests
    find('#unprocessed_review_request_header a').click

    # Click on student name to load review request.
    link = find('.student_request > a.student_name_link', text: student.full_name)
    link.click
  end
end
