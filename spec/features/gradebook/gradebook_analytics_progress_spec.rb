feature 'gradebook_analytics',
  js:true, chrome: true, new_gb_sync: true do

  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers

  let(:instructor) { create(:instructor) }
  let(:student_1) { create(:student) }
  let(:student_2) { create(:student) }
  let(:student_3) { create(:student) }
  let(:student_4) { create(:student) }
  let(:student_5) { create(:student) }
  let(:student_6) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:lesson) { program.units.first.lessons.first }
  let!(:course_1) do
    create(
      :course,
      first_unit_id: program.units.first.id,
      last_unit_id: program.units.last.id,
      owner: instructor,
      start_date: Date.today - 7.days - Date.today.wday,
      program: program
    )
  end
  let!(:course_2) do
    create(
      :course,
      first_unit_id: program.units.first.id,
      last_unit_id: program.units.last.id,
      owner: instructor,
      start_date: Date.today - 7.days - Date.today.wday,
      program: program
    )
  end
  let!(:category) { create(:category, course: course_1) }
  let!(:course_2_category) { create(:category, course: course_2) }
  let!(:section_1) { create(:section, course: course_1, instructor: instructor) }
  let!(:section_2) { create(:section, name: 'Section 2', course: course_1, instructor: instructor) }
  let!(:course_2_section_1) { create(:section, course: course_2, instructor: instructor) }
  let!(:course_2_section_2) { create(:section, course: course_2, instructor: instructor) }

  let(:activity) do
    create_activity_with_unit_lesson_and_concept(program, points_possible: 10)
  end

  let!(:assignment) do
    create(
      :assignment,
      assignable: activity,
      category: category,
      due_date: course_1.start_date,
      section: section_1
    )
  end

  let!(:section_2_assignment) do
    create(
      :assignment,
      assignable: activity,
      category: category,
      due_date: course_1.start_date,
      section: section_2
    )
  end

  let!(:course_2_section_1_assignment) do
    create(
      :assignment,
      assignable: activity,
      category: course_2_category,
      due_date: course_2.start_date,
      section: course_2_section_1
    )
  end

  let!(:course_2_section_2_assignment) do
    create(
      :assignment,
      assignable: activity,
      category: course_2_category,
      due_date: course_2.start_date,
      section: course_2_section_2
    )
  end

  before do
    create(:enrollment, user: student_1, section: section_1)
    create(:enrollment, user: student_2, section: section_1)
    create(:enrollment, user: student_3, section: section_2)
    create(:enrollment, user: student_4, section: section_2)
    create(:enrollment, user: student_5, section: course_2_section_1)
    create(:enrollment, user: student_6, section: course_2_section_2)
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  after do
    Capybara.execute_script 'sessionStorage.clear()'
  end

  scenario 'When selecting a section in the interstitial page' do
    visit instructor_dashboard_path(program_id: program.id)

    find_by_id('tour-guide-nav-grades').click # this is the Grade menu option
    click_link 'Gradebook'

    purpose 'Return to the section progress page after selecting the section' do
      step 'I see two sections in the interstitial page' do
        expect(page).to have_selector(".test-section_focusable_#{section_1.id}")
        expect(page).to have_selector(".test-section_focusable_#{section_2.id}")
      end

      step 'I am redirected to the interstitial page after navigating to the progress page' do
        click_link 'Analytics'
        click_link 'Progress'

        expect(page).to have_selector(".test-section_focusable_#{section_1.id}")
        expect(page).to have_selector(".test-section_focusable_#{section_2.id}")
      end

      step 'I see the progress page after selecting one of the sections' do
        click_link section_1.name, visible: true

        expect(page).to have_current_path(
          gradebook_engine.course_section_analytics_progress_path(
            program_id: program.id,
            course_id: course_1.id,
            section_id: section_1.id
          )
        )
      end
    end
  end

  scenario 'When I have filters set and change focus' do
    purpose 'When I switch to a different section within a course filters are preserved' do
      step 'Navigate to analytics' do
        visit gradebook_engine.course_section_scores_path(program_id: program.id,
                                                          course_id: course_1.id,
                                                          section_id: section_1.id)
        within('.test-gradebook-subnav') do
          click_link('Analytics')
          click_link('Progress')
        end
      end

      step 'Click on a point to drill down' do
        point = find('path[test-point-id="series-0-point-0"]')
        # The sleep is necessary because highcharts doesn't bind the
        # click event to the point as soon as it is rendered. There's a very
        # short delay between when the point is findable and when it is
        # interactable.
        # TODO: Find a way to detect that the click event has been bound, within
        # the standard Capaybara wait timeout, and only click once the binding
        # is done.
        sleep 0.4
        point.click
      end

      step 'I see the strands view for week' do
        expect(page).to have_text("Week 1 (#{course_1.start_date.strftime('%-m/%-d')}-#{(course_1.start_date + 6.days).strftime('%-m/%-d')}) by Strands")
      end

      step 'Change section focus' do
        find('.test-course-focus__header').click
        find(".test-section_#{section_2.id}").click
      end

      step 'I see the strand view for week for current section' do
        expect(page).to have_text("Week 1 (#{course_1.start_date.strftime('%-m/%-d')}-#{(course_1.start_date + 6.days).strftime('%-m/%-d')}) by Strands")
      end
    end

    purpose 'When I switch to a different course filters are reset' do
      step 'Change course focus' do
        find('.test-course-focus__header').click
        find(".test-section_#{course_2_section_1.id}").click
      end
      step 'I see the week view for current course' do
        expect(page).to have_text("Weekly View")
      end
    end

    purpose 'When I switch to a different section within a course, top level View By toggles and breadcrumbs are preserved' do
      step 'Change section focus' do
        # Since toggle button input fields are set to 1px x 1px, we need to use js to simulate the click
        page.execute_script("document.querySelector('.test-week-or-lesson_lesson').click()")
        find('.test-course-focus__header').click
        find(".test-section_#{course_2_section_2.id}").click
      end

      step 'I see the filter toggles for lesson' do
        elm = find(".test-week-or-lesson_lesson")
        expect(elm).to be_checked
      end

      step 'I see breadcrumbs for lesson' do
        expect(page).to have_css(".test-lesson-breadcrumb")
      end
    end

    purpose 'When I switch to another section in the course, I can still drill down' do
      step 'Change section focus' do
        find('.test-course-focus__header').click
        find(".test-section_#{course_2_section_2.id}").click
      end

      step 'Click on a point to drill down' do
        point = find('path[test-point-id="series-0-point-0"]')
        # TODO: Same as above.
        sleep 0.4
        point.click
      end

      step 'I see the strands view for lesson' do
        expect(page).to have_text("Lesson 1 by Strands")
      end
    end

    purpose 'When I switch to a different section within a course, drilled down View By toggles and breadcrumbs are preserved' do
      step 'Change section focus' do
        find('.test-course-focus__header').click
        find(".test-section_#{course_2_section_1.id}").click
      end

      step 'I see the filter toggles for the strands view for lesson' do
        elm = find(".test-lesson-strand-or-day_strand")
        expect(elm).to be_checked
      end

      step 'I see breadcrumbs for the strands view for lesson' do
        expect(page).to have_css(".test-lesson-sub-breadcrumb-set")
      end
    end

    purpose 'When I add a student and switch to a different section within a course, filters are preserved' do
      step 'Add a student from dropdown' do
        find('.test-student-select').find(:xpath, 'option[2]').select_option
      end

      step 'Change section focus' do
        find('.test-course-focus__header').click
        find(".test-section_#{course_2_section_2.id}").click
      end

      step 'I see the strands view for lesson' do
        expect(page).to have_text("Lesson 1 by Strands")
      end

      step 'I see breadcrumbs for the strands view for lesson' do
        expect(page).to have_css(".js-lesson-sub-breadcrumb-set")
      end
    end
  end
end
