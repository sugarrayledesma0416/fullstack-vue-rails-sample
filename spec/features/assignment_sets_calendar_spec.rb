feature 'Assignment Sets Calendar', js: true, chrome: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:school) { create(:school) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course) do
    create(
      :course,
      name: 'Course 1',
      owner: instructor,
      program: program,
      school: school,
      start_date: Time.zone.today.beginning_of_month,
      end_date: 20.weeks.from_now
    )
  end
  let(:lesson) { program.units.first.lessons.first }
  let(:course_package) { instance_double('Maestro::CoursePackage', id: 1) }

  let(:section) { create(:section, name: 'Section 1', instructor: instructor, course: course) }
  let(:section_2) { create(:section, name: 'Section 2', instructor: instructor, course: course) }

  # Set up 3 activities with determined toc_location_ranks so that the default
  # order is predictable.
  let(:activity_1) { create(:activity, lesson_id: lesson.id,  toc_location_rank: 10) }
  let(:activity_2) { create(:activity, lesson_id: lesson.id,  toc_location_rank: 20) }
  let(:activity_3) { create(:activity, lesson_id: lesson.id,  toc_location_rank: 30) }

  before do
    create(
      :assignment, due_date: Time.zone.today.next_month, section: section, assignable: activity_1
    )
    create(
      :assignment, due_date: Time.zone.today.next_month, section: section, assignable: activity_2
    )
    create(
      :assignment, due_date: Time.zone.today.next_month, section: section, assignable: activity_3
    )
    initialize_program_access_client_calls_for_instructor(instructor, program)
    allow(Maestro::CoursePackage).to receive(:all_for_course).and_return([course_package])
    instructor.schools << school
    create(:vol_program_config, program: program)
    log_in_as(instructor)
    visit instructor_assignment_sets_path(program_id: program.id)
    click_button(section.name)
  end

  # TODO: unpend once chromedriver is updated in build image per MAE-78490
  xscenario 'As an instructor I can view the assignment sets calendar' do
    purpose 'I can see and use the assignment sets calendar datepicker' do
      step 'I can view the assignment sets calendar' do
        expect(page).to have_css('.vc-container')
      end
      step 'the calendar is set on the current month' do
        month_string = Time.zone.today.strftime('%B %Y')
        month_header = page.find(class: 'vc-title')
        expect(month_header).to have_content(month_string)
      end
      step 'I see a message indicating there are no assignments' do
        expect(page.find('.test-no-assignments-message')).to be_visible
      end
      step 'I can change the date in order to see assignments' do
        within('.vc-container') do
          find('.is-right').click
          find('.is-first-day').click
          find('.is-last-day').click
          wait_for_ajax
        end
        # Confirm that the request pulled up activity assignments
        find_link(activity_1.title)
      end
      step 'I can reorder the assignments' do
        drag_source = page.find("#draggable-#{activity_3.id}")
        drag_target = page.find("#draggable-#{activity_1.id}")

        # First, confirm that the source is below the target in the dom, initially
        act_1_idx = page.body.index("draggable-#{activity_1.id}")
        act_3_idx = page.body.index("draggable-#{activity_3.id}")
        expect(act_3_idx > act_1_idx).to be true

        # Next, drag the activity from the bottom of the list to the top of the list
        # Note: There are ongoing bugs with drag and drop in chromedriver as of 09/2022
        # https://bugs.chromium.org/p/chromedriver/issues/detail?id=841 (old thread, but
        # still getting comments in 2022.)
        # Workaround: switch to selenium for js driver (uses firefox and firefox-geckodriver).
        # You may need to apt install firefix-geckodriver.
        original_js_driver = Capybara.javascript_driver # stash original driver
        Capybara.javascript_driver = :selenium # switch to FF
        drag_source.drag_to(drag_target)
        Capybara.javascript_driver = original_js_driver # switch back to original driver
        find('.custom-order-confirmation-dialog__buttons').find_button('continue').click
        wait_for_ajax

        # Confirm that the source moved to above the target in the dom & order dropdown visible
        act_1_idx = page.body.index("draggable-#{activity_1.id}")
        act_3_idx = page.body.index("draggable-#{activity_3.id}")
        expect(act_3_idx < act_1_idx).to be true
        expect(page.find('select[id^=order-select-set]')).to be_visible
      end
      step 'I can switch back to the default order' do
        page.select('Default Order')
        find('.default-order-confirmation-dialog__buttons').find_button('confirm').click
        wait_for_ajax
        
        expect(page).not_to have_selector('select[id^=order-select-set]')
        act_1_idx = page.body.index("draggable-#{activity_1.id}")
        act_3_idx = page.body.index("draggable-#{activity_3.id}")

        expect(act_3_idx > act_1_idx).to be true
      end
    end
  end
end
