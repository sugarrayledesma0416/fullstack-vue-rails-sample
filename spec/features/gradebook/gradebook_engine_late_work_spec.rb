feature 'Section Accept Late Work feature',
        chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers

  def click_checkbox(id)
    # There is some bug in headless chrome that prevents checking the box
    #   via Capybara's "click" if it's within <th> - this is a workaround:
    page.execute_script("document.getElementById('#{id}').click()")
  end

  def all_accepted?(activities, students)
    students.flat_map do |student|
      activities.map do |activity|
        GradebookEngine::CurrentScoreAction.by_user_and_activity(
          student.id, section.id, activity.id
        ).first
      end
    end.all?(&:late_work_accepted)
  end

  def none_accepted?(activities, students)
    students.flat_map do |student|
      activities.map do |activity|
        GradebookEngine::CurrentScoreAction.by_user_and_activity(
          student.id, section.id, activity.id
        ).first
      end
    end.none? { |score_action| score_action.summation.key?('late_work_accepted') }
  end

  def unset_section_focus
    find('.focus_indicator_course').click
    find("#js_course_#{course.id}").click
  end

  def go_to_gradebook
    visit instructor_dashboard_path(program_id: program)
    find('a.c-menu__title', text: 'Grade').click
    find('.js-gradebook-link').click

    unset_section_focus
  end

  def set_section_from_list(section_id)
    find(".test-section_focusable_#{section_id}").click
  end

  def set_section_from_dropdown(section_id)
    find('.focus_indicator_course').click
    find(".c-course-focus-list__item#js_section_#{section_id}").click
  end

  def expect_late_work_to_be_displayed
    expect(page).to have_content('Late Assignments')
    [student_1, student_2, student_3, student_4].each do |student|
      expect(page).to have_content("#{student.first_name} #{student.last_name} (3)")
    end
  end

  let(:instructor) { create(:instructor) }
  let(:student_1) { create(:student) }
  let(:student_2) { create(:student) }
  let(:student_3) { create(:student) }
  let(:student_4) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:lesson) { program.units.first.lessons.first }
  let(:other_lesson) { program.units[1].lessons.first }
  let(:concept) { create(:concept, lesson: lesson, program: program) }
  let(:other_concept) { create(:concept, lesson: other_lesson, program: program) }
  let(:activity_1) do
    GradebookEngine::Activity.create!(
      id: 123,
      lesson_id: lesson.id,
      points_possible: 20,
      rank: 10,
      strand_id: concept.id
    )
  end
  let(:activity_2) do
    GradebookEngine::Activity.create!(
      id: 231,
      lesson_id: lesson.id,
      points_possible: 30,
      rank: 20,
      strand_id: concept.id
    )
  end
  let(:activity_3) do
    GradebookEngine::Activity.create!(
      id: 312,
      lesson_id: other_lesson.id,
      points_possible: 40,
      rank: 10,
      strand_id: other_concept.id
    )
  end
  let(:activities) { [activity_1, activity_2, activity_3] }

  let(:course) do
    create(
      :course,
      first_unit_id: program.units.first.id,
      last_unit_id: program.units.last.id,
      owner: instructor,
      program: program
    )
  end

  let(:category) do
    create(
      :category,
      course: section.course,
      late_work_penalty: 'percent_per_day',
      name: 'Late Work',
      penalty_percent: 5
    )
  end

  let(:section) { create(:section, course: course, instructor: instructor) }

  before do
    create(:enrollment, user: student_1, section: section)
    create(:enrollment, user: student_2, section: section)
    create(:enrollment, user: student_3, section: section)
    create(:enrollment, user: student_4, section: section)

    activities.each do |activity|
      GradebookEngine::Assignment.create!(
        activity_id: activity.id,
        category_id: category.id,
        day_id: 2.days.ago,
        details: { points_possible: activity.points_possible },
        lesson_id: activity.lesson_id,
        section_id: section.id,
        strand_id: activity.strand.id
      )

      [student_1, student_2, student_3, student_4].each do |student|
        GradebookEngine::GradebookAPI.submit(
          student.id,
          section.id,
          activity.id,
          section.school_id,
          points_earned: 10,
          submitted_at: Time.now
        )
      end
    end

    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  context 'when there is late work to be accepted' do
    scenario 'I can accept various combinations of late work for various ' \
             'students', nondeterministic: true do
      # Visit page.
      visit gradebook_engine.course_section_show_late_work_path(
        course_id: course.id,
        program_id: program.id,
        section_id: section.id
      )

      # Select and accept late work for student 2.
      click_checkbox("section_late_work_checkbox_user_#{ student_2.id }")

      click_button('Accept')

      # The work for the student should be accepted;
      #   the work for the other students should not be accepted.
      #
      # The student with accepted work should not appear on the page.
      expect(
        all_accepted?(activities, [student_2])
      ).to be true

      expect(
        none_accepted?(activities, [student_1, student_3, student_4])
      ).to be true

      expect(page).to have_content("#{student_1.first_name} #{student_1.last_name}")
      expect(page).not_to have_content("#{student_2.first_name} #{student_2.last_name}")
      expect(page).to have_content("#{student_3.first_name} #{student_3.last_name}")
      expect(page).to have_content("#{student_4.first_name} #{student_4.last_name}")

      # Select and accept late work for all but student 3.
      click_checkbox('section_late_work_checkbox_all')
      click_checkbox("section_late_work_checkbox_user_#{ student_3.id }")

      click_button('Accept')

      expect(
        all_accepted?(activities, [student_1, student_4])
      ).to be true

      expect(
        none_accepted?(activities, [student_3])
      ).to be true

      # Create late work for another student and reload the page.
      student_5 = create(:student)
      create(:enrollment, user: student_5, section: section)

      activities.each do |activity|
        GradebookEngine::GradebookAPI.submit(student_5.id,
                                             section.id,
                                             activity.id,
                                             section.school_id,
                                             points_earned: 10,
                                             submitted_at: Time.now)
      end

      visit gradebook_engine.course_section_show_late_work_path(
        course_id: course.id,
        program_id: program.id,
        section_id: section.id
      )

      # Select and accept late work for one of student 3's assignments.
      click_checkbox("section_late_work_checkbox_user_#{ student_3.id }_activity_#{ activity_2.id }")
      click_button('Accept')

      # the late work for the submission is accepted
      expect(
        GradebookEngine::CurrentScoreAction.by_user_and_activity(student_3.id,
                                                                 section.id,
                                                                 activity_2.id)
        .first.late_work_accepted
      ).to be true

      # the other late work for that student is not accepted
      expect(
        none_accepted?([activity_1, activity_3], [student_3])
      ).to be true

      # the late work for student 5 is not accepted
      expect(
        none_accepted?(activities, [student_5])
      ).to be true

      # Select and accept late work for all but one of student 3's assignments.
      click_checkbox('section_late_work_checkbox_all')
      click_checkbox("section_late_work_checkbox_user_#{ student_3.id }_activity_#{ activity_3.id }")
      click_button('Accept')

      # the late work for the submission is not accepted
      expect(
        GradebookEngine::CurrentScoreAction.by_user_and_activity(student_3.id,
                                                                 section.id,
                                                                 activity_3.id)
        .first.summation.key?('late_work_accepted')
      ).to be false

      # the other late work for that student is accepted
      expect(
        GradebookEngine::CurrentScoreAction.by_user_and_activity(student_2.id,
                                                                 section.id,
                                                                 activity_1.id)
        .first.late_work_accepted
      ).to be true

      # the late work for the other student is accepted
      expect(
        all_accepted?(activities, [student_5])
      ).to be true

      # Select all late work.

      click_checkbox('section_late_work_checkbox_all')

      click_button('Accept')

      # get most recent score actions for all submissions; late? should be false for all.
      expect(
        all_accepted?(activities, [student_3])
      ).to be true

      # All late work is now accepted.
      expect(page).to have_content('No Late Work')
    end
  end

  scenario 'Setting and changing focus works when I click "Gradebook" and ' \
           'when I change focus while on the late-work page.' do
    # Create another section to force choice of section.
    create(:section, course: course, instructor: instructor, name: 'other section')

    # TODO: Add expectations.

    # Go to gradebook with no section in focus;
    #   click on late work;
    #   set focus from list.
    #
    # Expectation: late work for the section should be displayed.
    go_to_gradebook
    click_link('Late Work')
    set_section_from_list(section.id)

    expect_late_work_to_be_displayed

    # Go to gradebook with no section in focus;
    #   set focus from list;
    #   click on late work.
    #
    # Expectation: late work for the section should be displayed.
    go_to_gradebook
    set_section_from_list(section.id)
    click_link('Late Work')

    expect_late_work_to_be_displayed

    # Go to gradebook with no section in focus;
    #   click on late work, no section;
    #   set focus from dropdown.
    #
    # Expectation: late work for the section should be displayed.
    go_to_gradebook
    click_link('Late Work')
    set_section_from_dropdown(section.id)

    expect_late_work_to_be_displayed

    # Unset focus.
    #
    # Expectation: user should be prompted to choose a section for late work.
    unset_section_focus

    expect(page).to have_content('Select a section to see its late work.')
  end
end
