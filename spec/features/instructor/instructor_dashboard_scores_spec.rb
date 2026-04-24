feature 'Instructor dashboard scores',
        chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers

  let(:instructor) { create(:instructor) }
  let(:section_1_students) do
    Array.new(3) { create(:student) }
  end
  let(:section_2_students) do
    Array.new(6) { create(:student) }
  end
  let(:section_3_student) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:vol_program) { create(:vol_program) }
  let(:lesson) { program.units.first.lessons.first }
  let(:strand) { lesson.strands.first }
  let(:course_1) do
    create(
      :course,
      first_unit_id: program.units.first.id,
      last_unit_id: program.units.last.id,
      owner: instructor,
      program: program
    )
  end
  let(:course_2) do
    create(
      :course,
      first_unit_id: program.units.first.id,
      last_unit_id: program.units.last.id,
      owner: instructor,
      program: program,
      school_id: course_1.school_id
    )
  end
  let(:course_1_non_credit_category) do
    create(
      :non_credit_category,
      course: course_1,
      name: 'non-credit',
      weighting_percent: 50
    )
  end
  let(:course_1_credit_only_category) do
    create(
      :credit_only_category,
      course: course_1,
      name: 'credit-only',
      weighting_percent: 50
    )
  end
  let(:course_2_category) { create(:category, course: course_2) }
  let(:section_1) { create(:section, course: course_1, instructor: instructor) }
  let(:section_2) { create(:section, course: course_1, instructor: instructor) }
  let(:section_3) { create(:section, course: course_2, instructor: instructor) }
  let(:past_due_date) { 5.days.ago }
  let(:next_due_date) { 2.days.from_now }
  let(:section_2_score_attrs) do
    { pending: false, section: section_2, submitted_at: next_due_date }
  end
  let(:ss_title) { 'Supersite title' }
  let(:ss_body) { 'Supersite body' }
  let(:vol_title) { 'VOL title' }
  let(:vol_body) { 'VOL body' }

  before do
    instructor.schools << course_1.school
    section_1_students.each do |student|
      create(:enrollment, section: section_1, user: student)
    end
    section_2_students.each do |student|
      create(:enrollment, section: section_2, user: student)
    end
    create(:enrollment, section: section_3, user: section_3_student)
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  def widget_section_for(section)
    ".test-widget-container-section_#{section.id}"
  end

  def small_widget_for(section, widget_name)
    "#{widget_section_for(section)}-detail .test-widget.#{widget_name}"
  end

  def expect_activity_count(table, target_activity, count)
    expect(
      table.all("[data-activity-id='#{target_activity.id}'] td").map(&:text)
    ).to eq([target_activity.title, count.to_s])
  end

  def create_auto_graded_activity(args = {})
    create_activity(**args.merge(grading_method: 'auto'))
  end

  def create_instructor_graded_activity(args = {})
    create_activity(**args.merge(grading_method: 'instructor'))
  end

  def create_activity(grading_method:, title:, **args)
    create_activity_with_unit_lesson_and_concept(
      program,
      grading_method: grading_method,
      lesson: args.fetch(:lesson, lesson),
      strand_id: args.fetch(:strand_id, strand.location),
      title: title
    )
  end

  def create_score(activity:, student:, **args)
    score_attrs = {
      activity: activity,
      pending: args.fetch(:pending, true),
      section: args.fetch(:section, section_1),
      student: student,
      submitted_at: args.fetch(:due_date, past_due_date)
    }
    create_gradebook_engine_submission(**score_attrs)
  end

  def assign_and_creating_pending_scores(activity:, category:, **args)
    create(
      :assignment,
      assignable: activity,
      category: category,
      due_date: past_due_date,
      section: section_1
    )
    create_score(**args.merge(activity: activity, pending: true))
  end

  scenario 'As an instructor, I only see data from the new gradebook on the ' \
           'instructor dashboard' do
    # Section 1:
    # Create an auto-graded activity due in the past worth 10 pts.
    # Use to validate the cumulative score.
    section_1_auto_graded_activity = create_auto_graded_activity(
      points_possible: 10, title: 'section_1_auto'
    )
    create(
      :assignment,
      assignable: section_1_auto_graded_activity,
      category: course_1_non_credit_category,
      due_date: past_due_date,
      section: section_1
    )

    # We need 4 instructor-graded activities with submissions, assignments,
    section_1_activities = Array.new(5) do |index|
      create_instructor_graded_activity(points_possible: 10, title: "s1_ig_#{index}")
    end
    # One activity is in a credit only category. It shouldn't show up, even
    # if it has pending scores.
    assign_and_creating_pending_scores(
      activity: section_1_activities.first,
      category: course_1_credit_only_category,
      student: section_1_students.first
    )
    # The second activity is assigned in non-credit category
    # but has no student submissions.
    create(
      :assignment,
      assignable: section_1_activities[1],
      category: course_1_non_credit_category,
      due_date: past_due_date,
      section: section_1
    )

    # Nerdy student[0] has completed all the activities.
    section_1_activities[2..4].each do |activity|
      assign_and_creating_pending_scores(
        activity: activity,
        category: course_1_non_credit_category,
        student: section_1_students.first
      )
    end

    # Two students have completed the third activity.
    section_1_students[1..2].each do |student|
      create_score(activity: section_1_activities.third, student: student)
    end

    # One of those two students is slightly more motivated and has also
    # submitted the fourth activity.
    create_score(
      activity: section_1_activities.fourth, student: section_1_students[1]
    )

    # Section 2:
    # Exercise assignment counts

    # 2 auto-graded activities are assigned on the same day, the "next due date"
    section_2_activities = [
      create_auto_graded_activity(title: 's2_auto_1'),
      create_auto_graded_activity(title: 's2_auto_2')
    ]
    section_2_activities.each do |activity|
      create(
        :assignment,
        assignable: activity,
        category: course_2_category,
        due_date: next_due_date,
        section: section_2
      )
    end
    # student 1 completed both the activities
    section_2_activities.each do |activity|
      student = section_2_students.first
      create_score(
        **section_2_score_attrs.merge(activity: activity, student: student)
      )
    end
    # students 2 and 3 completed 1 activity
    section_2_students[1..2].each do |student|
      activity = section_2_activities.first
      create_score(
        **section_2_score_attrs.merge(activity: activity, student: student)
      )
    end
    # students 4, 5, and 6 have done nothing.

    visit instructor_dashboard_path(program.id)
    page.find(".test-section-name[data-section-id='#{section_1.id}']").click

    # new gradebook, counting past due pending in credit category as 100%?
    assert_selector(small_widget_for(section_1, 'test-cumulative-grade'), text: '16.7%')

    # Should only be 3, the credit-only activity shouldn't appear, and the
    # activity with no submissions should not appear.
    to_grade_count = find(
      "#{small_widget_for(section_1, 'test-activities-to-grade')} .test-widget-numbers"
    ).text

    expect(to_grade_count).to eq('3')

    table = find("#{widget_section_for(section_1)}-detail .test-activities-to-grade-table")

    # The first activity, assigned in the credit only category should not appear.
    expect(table).not_to have_selector(
      "[data-activity-id='#{section_1_activities[0].id}']"
    )
    # The second activity, assigned in the non-credit but with no pending
    # submissions, should not appear.
    expect(table).not_to have_selector(
      "[data-activity-id='#{section_1_activities[1].id}']"
    )
    # The third activity was submitted by all the students.
    expect_activity_count(table, section_1_activities[2], 3)
    # The fourth activity was submitted by two students.
    expect_activity_count(table, section_1_activities[3], 2)
    # The fifth activity was submitted by only one student.
    expect_activity_count(table, section_1_activities[4], 1)

    first(".test-section-name[data-section-id='#{section_2.id}']").click
    assignment_stats = all(
      "#{widget_section_for(section_2)}-detail .test-graph-number"
    )
    expect(assignment_stats.map(&:text)).to eq(
      ['Completed' ,'1', 'Incomplete', '2', 'Not yet started', '3']
    )
    purpose 'I can see an active dashboard announcement' do
      step 'I see no dashboard announcement if none is visible' do
        visit instructor_dashboard_path(program.id)
        expect(page).to have_no_text('Here is the body')
      end
      step 'I see a dashboard announcement if one is visible for a Supersite program' do
        create(:dashboard_announcement,
               title: ss_title,
               body: ss_body,
               vol: false,
               supersite: true)
        visit instructor_dashboard_path(program.id)
        within('.test-dashboard-announcement') do
          expect(page).to have_text(ss_title.upcase)
          expect(page).to have_text(ss_body)
        end
      end
      step 'I see the dashboard announcement for a VOL program' do
        create(:dashboard_announcement,
               title: vol_title,
               body: vol_body,
               supersite: false,
               vol: true)
        initialize_program_access_client_calls_for_instructor(instructor, vol_program)
        visit instructor_dashboard_path(vol_program.id)
        within('.test-dashboard-announcement') do
          expect(page).to have_text(vol_title.upcase)
          expect(page).to have_text(vol_body)
          expect(page).to have_no_text(ss_title.upcase)
          expect(page).to have_no_text(ss_body)
        end
      end
      step 'I do not see a dashboard announcement if it is not visible' do
        DashboardAnnouncement.where(title: vol_title).first.update(vol: false)
        visit instructor_dashboard_path(vol_program.id)
        expect(page).to have_no_selector('.test-dashboard-announcement')
      end
      step 'I do not see an announcement if I hide it' do
        DashboardAnnouncement.where(title: vol_title).first.update(vol: true)
        visit instructor_dashboard_path(vol_program.id)
        find('button.test-dismiss-announcement').click
        expect(page).to have_no_text(vol_title.upcase)
        expect(page).to have_no_text(vol_body)
      end
      step 'I see a new announcement even if a previous one was dismissed' do
        DashboardAnnouncement.where(title: vol_title).first.update(vol: false)
        create(:dashboard_announcement,
               title: 'New title',
               body: 'New body',
               supersite: false,
               vol: true)
        visit instructor_dashboard_path(vol_program.id)
        expect(page).to have_no_text(vol_title.upcase)
        expect(page).to have_no_text(vol_body)
        expect(page).to have_text('NEW TITLE')
        expect(page).to have_text('New body')
      end
    end
  end
end
