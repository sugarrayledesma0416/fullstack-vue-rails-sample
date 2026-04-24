feature 'Instructor viewing student dashboard',
        js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include DateTimeHelper

  let(:school) { create(:school) }
  let(:instructor) { create(:instructor, schools: [school]) }
  let(:program) { create(:program) }
  let(:unit_1) { create(:unit, program: program, name: 'UNIT-01', rank: 1) }
  let(:unit_2) { create(:unit, program: program, name: 'UNIT-02', rank: 2) }
  let(:lesson_1_strand_a) { create(:toc_entry, title: 'strand_a') }
  let(:lesson_1_strand_b) { create(:toc_entry, title: 'strand_b') }
  let(:lesson_2_strand_c) { create(:toc_entry, title: 'strand_c') }
  let(:lesson_2_strand_d) { create(:toc_entry, title: 'strand_d') }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, instructor: instructor, course: course) }

  let(:lesson_1) do
    create(
      :lesson,
      unit: unit_1,
      name: 'Lesson 1',
      toc_entries: [lesson_1_strand_a, lesson_1_strand_b]
    )
  end
  let(:lesson_2) do
    create(
      :lesson,
      unit: unit_2,
      name: 'Lesson 2',
      toc_entries: [lesson_2_strand_c, lesson_2_strand_d]
    )
  end
  let(:course_licenses) { [] }

  def create_activity(lesson, strand)
    create(
      :activity,
      concept: lesson.concepts.find_by(id: strand.location),
      lesson: lesson,
      minutes_to_complete: 10,
      toc_location: strand.location
    )
  end

  def assign_activity(activity, due_date)
    create(
      :assignment,
      assignable: activity,
      due_date: due_date,
      section: section
    )
  end

  def create_concept_for_toc_entries(lesson)
    lesson.strands.each_with_index do |strand, index|
      create_concept_matching_strand_id(strand, name: strand.title, rank: index, lesson: lesson)
    end
  end

  scenario 'As an instructor, I can preview the student dashboard' do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    course_licenses << Maestro::CourseLicense.new('license_group' => { 'id' => 1, 'demo' => false })
    allow(Maestro::CourseLicense).to receive(:all).and_return(course_licenses)
    log_in_as(instructor)

    create_concept_for_toc_entries(lesson_1)
    create_concept_for_toc_entries(lesson_2)

    activity_1 = create_activity(lesson_1, lesson_1_strand_a)
    activity_2 = create_activity(lesson_1, lesson_1_strand_b)
    activity_3 = create_activity(lesson_2, lesson_2_strand_c)
    activity_4 = create_activity(lesson_2, lesson_2_strand_d)

    future_due_date = 2.days.from_now.to_date
    future_label = format_date_time(future_due_date, :weekday_month_ordinal)

    assign_activity(activity_1, 2.weeks.ago.to_date)
    assign_activity(activity_2, 2.days.ago.to_date)
    assign_activity(activity_3, future_due_date)
    assign_activity(activity_4, future_due_date)

    visit course_section_path(course.id, section.id, preview: 'true')

    expect(page).to have_selector('h1')

    purpose 'I see overdue assignments collapsed' do
      expect(page).to have_selector('.test-assignment-day', text: 'Overdue')
      expect(page).to have_selector(
        '.assignments',
        text: lesson_1_strand_a.title,
        visible: :hidden
      )
    end

    purpose 'I see future-due assignments expanded' do
      expect(page).to have_selector('.test-assignment-day', text: future_label)
      expect(page).to have_selector(
        '.assignments',
        text: lesson_2_strand_c.title,
        visible: :visible
      )
    end

    purpose 'I am not able to click the start button for a workset' do
      # When the user clicks on the button, the browser should remain on the current page.
      find('.test-start-button', visible: :visible).click
      url = page.current_url
      expect(url).to include(course_section_path(course.id, section.id, preview: 'true'))
    end

    program.update!(family: 'vista_online_learning')

    visit course_section_path(course.id, section.id, preview: 'true')

    expect(page).to have_selector('h1')

    purpose 'I am not able to click the links for a strand' do
      expect(page).to have_link(
        "#{lesson_2.name} : #{lesson_2_strand_c.title}",
        class: 'test-strand-group-link',
        href: '#'
      )
      expect(page).to have_link(
        "#{lesson_2.name} : #{lesson_2_strand_d.title}",
        class: 'test-strand-group-link',
        href: '#'
      )
    end

    purpose 'I am not able to click the start button for a workset' do
      expect(page).to have_selector(
        '.test-workset-start-button[data-js-workset-path="#"]'
      )
    end

    purpose 'I am not able to click the links for a strand for a previous ' \
            'due date' do
      click_link('Previous Due Dates')
      wait_for_ajax

      expect(page).to have_link(
        "#{lesson_1.name} : #{lesson_1_strand_b.title}",
        class: 'test-strand-group-link',
        href: '#'
      )
    end

    purpose 'I am not able to click the start button for a workset on ' \
            'a previous due date' do
      expect(page).to have_selector(
        '.test-workset-start-button[data-js-workset-path="#"]'
      )
    end
  end
end
