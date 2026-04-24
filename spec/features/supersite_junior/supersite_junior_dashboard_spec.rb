feature 'Supersite Junior Dashboard', js: true, chrome: true, new_gb_sync: true do
  include RspecJsApiHelpers
  include RspecJsCommonHelpers

  let(:program) { create(:ss_jr_program) }
  let(:school) { create(:school) }
  let(:student) { create(:student) }
  let(:instructor) { create(:instructor, schools: [school]) }
  let(:unit) { create(:unit, program: program) }
  let(:lesson) { create(:lesson, unit: unit) }
  let(:course) { create(:course, owner: instructor, program: program, school: school) }
  let(:section) { create(:section, instructor: instructor, course: course) }
  let(:strand_1_name) { 'Strand 1' }
  let(:strand_2_name) { 'Strand 2' }
  let(:strand_1) { create(:toc_entry, title: strand_1_name) }
  let(:strand_2) { create(:toc_entry, title: strand_2_name) }
  let(:due_date_1) { 1.day.from_now.to_date }
  let(:due_date_2) { 10.days.from_now.to_date }
  let(:strand_1_image) { create(:media_item_image, filename: 'strand_1.png') }
  let(:strand_2_image) { create(:media_item_image, filename: 'strand_2.png') }

  let(:concept_1) do
    create(
      :concept,
      id: strand_1.location,
      lesson: lesson,
      media_item: strand_1_image,
      name: strand_1_name
    )
  end

  let(:concept_2) do
    create(
      :concept,
      id: strand_2.location,
      lesson: lesson,
      media_item: strand_2_image,
      name: strand_2_name
    )
  end

  let(:strand_1_activity_1) do
    create(:activity, concept: concept_1, lesson: lesson)
  end

  let(:strand_1_activity_2) do
    create(:activity, concept: concept_1, lesson: lesson)
  end

  let(:strand_1_activity_3) do
    create(:activity, concept: concept_1, lesson: lesson)
  end

  let(:strand_2_activity_1) do
    create(:activity, concept: concept_2, lesson: lesson)
  end

  let(:strand_2_activity_2) do
    create(:activity, concept: concept_2, lesson: lesson)
  end

  let(:strand_2_activity_3) do
    create(:activity, concept: concept_2, lesson: lesson)
  end

  let(:category) { create(:category, course: course) }

  let(:no_upcoming_work_message) { 'You have no upcoming homework, but...' }

  def student_dashboard_url
    jr_course_section_path(course_id: course.id, section_id: section.id)
  end

  def link_image(media_item, fixture_file)
    source_path = File.join('spec', 'fixtures', 'media_items', fixture_file)
    dest_path = media_item.full_filename
    FileUtils.makedirs(File.dirname(dest_path))
    FileUtils.cp(source_path, dest_path)
    @recycle_bin << dest_path
  end

  before do
    link_image(strand_1_image, 'ssjr_strand_1.png')
    link_image(strand_2_image, 'ssjr_strand_2.png')
    create(:active_enrollment, section: section, user: student)
    initialize_program_access_client_calls_for_user_and_program(student, program)
    give_user_access_to_program(student, program)
    log_in_as(student)
    lesson.toc_entries = [strand_1, strand_2]
    lesson.save!
  end

  def assign(activity, due_date)
    create(
      :assignment,
      assignable: activity,
      category: category,
      due_date: due_date,
      section: section
    )
  end


  scenario 'As a student, I see one workset groups on the student dashboard ' \
           'for each strand for a given due date' do
    visit student_dashboard_url

    purpose 'I see a message and no lozenges when I have no assignments' do
      expect(page).to have_content('Hooray!')

      expect(page).to have_content('You have no homework.')

      expect(page).to have_no_selector('.test-lozenge-1')
    end

    purpose 'I see a message, an overdue work lozenge, and no future ' \
            'assignment lozenges if I have only overdue assignments' do
      assign(strand_1_activity_1, 2.days.ago.to_date)

      visit student_dashboard_url

      expect(page).to have_no_selector('.test-lozenge-1')

      expect(page).to have_content(no_upcoming_work_message)

      within('.test-overdue-lozenge') do
        expect(page).to have_content('Oops! You have overdue work.')
        click_button('Go')
      end

      expect(page).to have_current_path(
        gradebook_engine.jr_section_progress_path(
          program_id: program.id,
          section_id: section.id
        )
      )
    end

    purpose 'I see a message, an overdue work lozenge, and future ' \
            'assignment lozenges if I have both overdue and non-overdue ' \
            'assignments' do
      assign(strand_1_activity_2, due_date_1)

      visit student_dashboard_url

      expect(page).to have_no_content(no_upcoming_work_message)

      within('.test-lozenge-1') do
        expect(page).to have_selector('.test-due-date', text: 'Tomorrow')
        expect(page).to have_selector('.test-strand-name', text: strand_1_name)
        expect(page).to have_selector('.test-assignment-count', text: '1 assignment')
      end

      within('.test-overdue-lozenge') do
        expect(page).to have_content('Overdue Assignments!')
        click_button('Go')
      end

      expect(page).to have_current_path(
        gradebook_engine.jr_section_progress_path(
          program_id: program.id,
          section_id: section.id
        )
      )
    end

    Assignment.find_by(assignable_id: strand_1_activity_1.id).update!(
      due_date: due_date_1
    )
    assign(strand_1_activity_3, due_date_2)
    assign(strand_2_activity_1, due_date_1)
    assign(strand_2_activity_2, due_date_1)
    assign(strand_2_activity_3, due_date_2)

    visit student_dashboard_url

    within('.test-lozenge-1') do
      expect(page).to have_selector('.test-due-date', text: 'Tomorrow')
      expect(page).to have_selector('.test-strand-name', text: strand_1_name)
      expect(page).to have_selector("img[src*='strand_1.png']")
      expect(page).to have_selector('.test-lesson-name', text: lesson.display_name)
      expect(page).to have_selector('.test-assignment-count', text: '2 assignments')

      form_action = section_assignment_bank_path(
        assignment_day: due_date_1,
        concept_id: concept_1.id,
        section_id: section.id,
        rank_range: '0..0'
      )
      form_element = find('form')
      expect(form_element['action']).to end_with(form_action)
    end

    within('.test-lozenge-2') do
      expect(page).to have_selector('.test-due-date', text: 'Tomorrow')
      expect(page).to have_selector('.test-strand-name', text: strand_2_name)
      expect(page).to have_selector("img[src*='strand_2.png']")
      expect(page).to have_selector('.test-lesson-name', text: lesson.display_name)
      expect(page).to have_selector('.test-assignment-count', text: '2 assignments')

      form_action = section_assignment_bank_path(
        assignment_day: due_date_1,
        concept_id: concept_2.id,
        section_id: section.id,
        rank_range: '0..0'
      )
      form_element = find('form')
      expect(form_element['action']).to end_with(form_action)
    end

    due_date_2_text = due_date_2.strftime('%b %d')
    within('.test-lozenge-3') do
      expect(page).to have_selector('.test-due-date', text: due_date_2_text)
      expect(page).to have_selector('.test-strand-name', text: strand_1_name)
      expect(page).to have_selector("img[src*='strand_1.png']")
      expect(page).to have_selector('.test-lesson-name', text: lesson.display_name)
      expect(page).to have_selector('.test-assignment-count', text: '1 assignment')

      form_action = section_assignment_bank_path(
        assignment_day: due_date_2,
        concept_id: concept_1.id,
        section_id: section.id,
        rank_range: '0..0'
      )
      form_element = find('form')
      expect(form_element['action']).to end_with(form_action)
    end

    within('.test-lozenge-4') do
      expect(page).to have_selector('.test-due-date', text: due_date_2_text)
      expect(page).to have_selector('.test-strand-name', text: strand_2_name)
      expect(page).to have_selector("img[src*='strand_2.png']")
      expect(page).to have_selector('.test-lesson-name', text: lesson.display_name)
      expect(page).to have_selector('.test-assignment-count', text: '1 assignment')

      form_action = section_assignment_bank_path(
        assignment_day: due_date_2,
        concept_id: concept_2.id,
        section_id: section.id,
        rank_range: '0..0'
      )
      form_element = find('form')
      expect(form_element['action']).to end_with(form_action)
    end

    purpose 'I do not see lozenges for strands where all the assignments ' \
            'have been completed' do
      create(
        :attempt_completed,
        activity: strand_1_activity_1,
        section: section,
        user: student
      )
      create(
        :attempt_completed,
        activity: strand_1_activity_2,
        section: section,
        user: student
      )

      visit student_dashboard_url

      # Now that all the strand 1 activities are completed, the first
      # lozenge should be for strand 2.
      within('.test-lozenge-1') do
        expect(page).to have_selector('.test-due-date', text: 'Tomorrow')
        expect(page).to have_selector('.test-strand-name', text: strand_2_name)
        expect(page).to have_selector("img[src*='strand_2.png']")
        expect(page).to have_selector('.test-lesson-name', text: lesson.display_name)
        expect(page).to have_selector('.test-assignment-count', text: '2 assignments')

        form_action = section_assignment_bank_path(
          assignment_day: due_date_1,
          concept_id: concept_2.id,
          section_id: section.id,
          rank_range: '0..0'
        )
        form_element = find('form')
        expect(form_element['action']).to end_with(form_action)
      end
    end

    purpose 'I see the correct language and link if I try to access a ' \
            'workset with no assignments in it directly via the URL' do
      workset_url = section_assignment_bank_path(
        assignment_day: (due_date_1 + 1.day),
        concept_id: concept_1.id,
        section_id: section.id,
        rank_range: '0..0'
      )

      visit workset_url

      expect(page).to have_content('All done for now!')

      expect(page).to have_link('Go to Dashboard', href: student_dashboard_url)
    end

    purpose 'I see an updated assignment count when I complete activities' do
      create(
        :attempt_completed,
        activity: strand_2_activity_1,
        section: section,
        user: student
      )

      visit student_dashboard_url

      within('.test-lozenge-1') do
        expect(page).to have_selector('.test-assignment-count', text: '1 assignment')

        form_action = section_assignment_bank_path(
          assignment_day: due_date_1,
          concept_id: concept_2.id,
          section_id: section.id,
          rank_range: '0..0'
        )
        form_element = find('form')
        expect(form_element['action']).to end_with(form_action)
      end
    end

    purpose 'I see a message and no lozenges when I have completed all ' \
            'future assignments' do
      create(
        :attempt_completed,
        activity: strand_1_activity_3,
        section: section,
        user: student
      )
      create(
        :attempt_completed,
        activity: strand_2_activity_2,
        section: section,
        user: student
      )
      create(
        :attempt_completed,
        activity: strand_2_activity_3,
        section: section,
        user: student
      )

      visit student_dashboard_url
      expect(page).to have_content('Hooray!')

      expect(page).to have_content('You have no homework.')

      expect(page).to have_no_selector('.test-lozenge-1')
    end
  end
end
