require 'timecop'

feature 'gradebook_analytics', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers

  def create_score(activity:, date:, points:, time_spent:, user: nil)
    common_attrs = {
      activity_id: activity.id,
      section_id: section.id,
      user_id: user.id
    }
    create(:gb_attempt_duration, common_attrs.merge(seconds_spent: time_spent))
    create(
      :gb_score_action,
      common_attrs.merge(
        summation: {
          'points_earned' => points,
          'submitted_at' => date,
          'time_spent' => time_spent
        }
      )
    )
  end

  let(:instructor) { create(:instructor) }
  let(:student_1) { create(:student) }
  let(:student_2) { create(:student) }
  let(:future_student) { create(:student) }
  let(:future_student_2) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:lesson) { program.units.first.lessons.first }
  let(:category) { create(:category, course: course) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:course) do
    create(
      :course,
      first_unit_id: program.units.first.id,
      last_unit_id: program.units.last.id,
      owner: instructor,
      program: program,
      start_date: Date.new(2019, 2, 1)
    )
  end

  let(:non_recent_activity) do
    create_activity_with_unit_lesson_and_concept(program, points_possible: 10)
  end

  let(:recent_activity) do
    create_activity_with_unit_lesson_and_concept(program, points_possible: 10)
  end

  let(:future_activity) do
    create_activity_with_unit_lesson_and_concept(program, points_possible: 10)
  end

  let(:course_with_future_assignment) do
    create(
      :course,
      owner: instructor,
      program: program,
      start_date: (Date.today - 1.week)
    )
  end

  let(:future_category) do
    create(:category, course: course_with_future_assignment)
  end

  let(:future_section) do
    create(
      :section,
      course: course_with_future_assignment,
      instructor: instructor
    )
  end

  # Use fixed time to make date range determinative.
  around do |example|
    Timecop.freeze(Time.new(2019, 3, 1, 12, 0, 0)) do
      example.run
    end
  end

  before do
    # Create three assignments:
    #   Two of the assignments are due.
    #
    #   The third is due in the future, to test that the assignment counts
    #   include due assignments only.
    #
    #   Two assignments * two students = four submissions,
    #   which is enough to demonstrate that we can get counts
    #   for late, missing, and on time.
    #
    #   One assignment should be outside of the current date range
    #   to show that we are calculating both recent and cumulative stats.
    create(
      :assignment,
      assignable: non_recent_activity,
      category: category,
      due_date: Date.new(2019, 2, 8),
      section: section
    )
    create(
      :assignment,
      assignable: recent_activity,
      category: category,
      due_date: Date.new(2019, 2, 26),
      section: section
    )
    create(
      :assignment,
      assignable: future_activity,
      category: category,
      due_date: Date.new(2019, 4, 3),
      section: section
    )
    # Create an assignment in a section that only has assignments due in
    # the future.
    create(
      :assignment,
      assignable: future_activity,
      category: future_category,
      due_date: Date.new(2019, 4, 3),
      section: future_section
    )
    create(:enrollment, user: student_1, section: section)
    create(:enrollment, user: student_2, section: section)
    create(:enrollment, user: future_student, section: future_section)
    create(:enrollment, user: future_student_2, section: future_section)
    # User 1 submits the older assignment on time,
    #   and the newer assignment late.
    create_score(
       activity: non_recent_activity,
       date: Date.new(2019, 2, 7),
       points: 9,
       time_spent: 5400,
       user: student_1
    )
    create_score(
       activity: recent_activity,
       date: Date.new(2019, 2, 27),
       points: 9,
       time_spent: 2700,
       user: student_1
    )
    # User 2 submits the newer assignment on time,
    #   and does not submit the older assignment.
    create_score(
       activity: recent_activity,
       date: Date.new(2019, 2, 25),
       points: 8,
       time_spent: 5280,
       user: student_2
    )
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  scenario 'As an instructor navigating to the analytics overview' do
    visit gradebook_engine.course_section_scores_path(program_id: program.id,
                                                      course_id: course.id,
                                                      section_id: section.id)
    within('.test-gradebook-subnav') do
      click_link('Analytics')
      click_link('Overview')
    end

    purpose 'I can see recent and cumulative stats' do
      step 'I see a date range for the Sunday before last through today' do
        expect(find('.test-date_range')).to have_text('Feb 17 - Today')
      end

      step 'I see the expected recent and cumulative average score' do
        # User 1: 90 * 0.95
        # User 2: 80
        expect(find('.test-overview_score_recent'))
          .to have_text('82.8%')

        # User 1: ((90 * 0.95) + 90) / 2
        # User 2: (0 + 80) / 2
        expect(find('.test-overview_score_cumulative'))
          .to have_text('63.9%')
      end

      step 'I see the expected recent and cumulative average time spent' do
        # User 1: 2700
        # User 2: 5280
        expect(find('.test-overview_time_spent_recent'))
          .to have_text('1hr 7m')

        # User 1: 8100
        # User 2: 5280
        expect(find('.test-overview_time_spent_cumulative'))
          .to have_text('1hr 52m')
      end

      step 'I see the recent submissions stats by default' do
        recent_assignment_count_div = find('.test-overview_assignment_count_recent')
        cumulative_assignment_count_div = find('.test-overview_assignment_count_cumulative')

        expect(recent_assignment_count_div).to be_visible
        expect(recent_assignment_count_div).to have_text('1')
        expect(cumulative_assignment_count_div).not_to be_visible

        recent_donut_div = find('.test-recent_donut')
        cumulative_donut_div = find('.test-cumulative_donut')

        expect(recent_donut_div).to be_visible
        expect(cumulative_donut_div).not_to be_visible

        expect(recent_donut_div['data-late-percent']).to eq('50')
        expect(recent_donut_div['data-missing-percent']).to eq('0')
        expect(recent_donut_div['data-on-time-percent']).to eq('50')
      end

      step 'I can click on the cumulative submissions tab to see cumulative submissions stats' do
        find('.js-submissions-cumulative').click

        recent_assignment_count_div = find('.test-overview_assignment_count_recent')
        cumulative_assignment_count_div = find('.test-overview_assignment_count_cumulative')

        expect(cumulative_assignment_count_div).to be_visible
        expect(cumulative_assignment_count_div).to have_text('2')
        expect(recent_assignment_count_div).not_to be_visible

        recent_donut_div = find('.test-recent_donut')
        cumulative_donut_div = find('.test-cumulative_donut')

        expect(cumulative_donut_div).to be_visible
        expect(recent_donut_div).not_to be_visible

        expect(cumulative_donut_div['data-late-percent']).to eq('25')
        expect(cumulative_donut_div['data-missing-percent']).to eq('25')
        expect(cumulative_donut_div['data-on-time-percent']).to eq('50')
      end

      step 'I can click on the recent submissions tab to see recent submissions stats again' do
        find('.js-submissions-recent').click

        recent_assignment_count_div = find('.test-overview_assignment_count_recent')
        cumulative_assignment_count_div = find('.test-overview_assignment_count_cumulative')

        expect(recent_assignment_count_div).to be_visible
        expect(cumulative_assignment_count_div).not_to be_visible

        recent_donut_div = find('.test-recent_donut')
        cumulative_donut_div = find('.test-cumulative_donut')

        expect(recent_donut_div).to be_visible
        expect(cumulative_donut_div).not_to be_visible
      end

      step 'I see expected values in the student table for recent activity' do
        expect(find(".test-#{student_1.id}-score")).to have_text('85.5')
        expect(find(".test-#{student_1.id}-trend")).to have_text('-2%')
        expect(find(".test-#{student_1.id}-late")).to have_text('100%')
        expect(find(".test-#{student_1.id}-missing")).to have_text('0%')
        expect(find(".test-#{student_2.id}-score")).to have_text('80.0')
        expect(find(".test-#{student_2.id}-trend").text).to match(/^N\/A$/)
        expect(find(".test-#{student_2.id}-late")).to have_text('0%')
        expect(find(".test-#{student_2.id}-missing")).to have_text('0%')
      end
    end
  end

  scenario 'As an instructor with only future assignments in the section' do
    purpose 'I do not get a server error on the overview page' do
      step 'I can see the overview page' do
        visit gradebook_engine.course_section_scores_path(
          program_id: program.id,
          course_id: course_with_future_assignment.id,
          section_id: future_section.id
        )

        within('.test-gradebook-subnav') do
          click_link('Analytics')
          click_link('Overview')
        end

        expect(page).to have_selector(
          '.test-date_range', text: 'Feb 17 - Today'
        )

        # 2 students X 4 "N/A" per student row
        expect(page.text.scan('N/A').size).to eq(8)
      end
    end
  end
end
