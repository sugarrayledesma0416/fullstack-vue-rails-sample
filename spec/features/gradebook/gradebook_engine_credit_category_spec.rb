feature 'Viewing for-credit student submissions in the new gradebook',
        chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:category) do
    create(
      :category,
      accept_late_work: true,
      course: course,
      credit_only: true,
      late_work_penalty: 'percent_per_day',
      penalty_percent: 50
    )
  end
  let(:section) { create(:section, course: course, instructor: instructor) }

  # Instructor-graded activity type
  let(:activity) { create_open_ended_activity(program) }
  let(:concept) { activity.concept }
  let(:lesson) { activity.lesson }
  let(:strand) { activity.strand }

  let(:attempt_results) do
    # The student left everything blank so they got 0 points.
    MaestroActivityEngine::ActivityContent::Results
      .new(activity.content_object).tap do |results|
      results.add(label: 'question_01', response: '')
      results.add(label: 'question_02', response: '')
      results.add(label: 'question_03', response: '')
      results.add(label: 'question_04', response: '')
    end
  end

  let(:sandbox_student_grade_css_class) do
    ".test-user_#{student.id}_grade_#{activity.id}.js-show-grade-details"
  end

  # Some functionality still only exists in the sandbox.
  def sandbox_activities_for_lesson_url
    gradebook_engine.sandbox_program_course_gradebook_path(
      program.id,
      course.id,
      level: 'activity',
      summary_level: 'lesson',
      summary_level_id: lesson.id
    )
  end

  before do
    create(:enrollment, user: student, section: section)
    # Assignment due date is yesterday so that activity is overdue when
    # submitted.
    create(
      :assignment,
      assignable: activity,
      category: category,
      due_date: Date.yesterday,
      section: section
    )
    create(:attempt_completed, activity: activity, section: section, user: student)
    allow_any_instance_of(Attempt).to receive(:results) { attempt_results }
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  scenario 'As an instructor, late student-submissions do not show as ' \
    'pending in a credit-only category' do
    # The student has submitted the activity late
    # The activity is worth 40 points, with a penalty of 50% off per day
    Timecop.freeze(GradebookEngine::Assignment.first.due_date + 5.minutes) do
      create_gradebook_engine_submission(submitted_at: Time.now.utc)

      # Go to the production gradebook page showing activity-level scores.
      visit activities_for_lesson_url

      expect_cell(student.id, activity.id, percent: 50.0, points: 20.0, late: true)
    end
  end
end
