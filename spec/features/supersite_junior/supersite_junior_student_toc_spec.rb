feature 'Supersite Junior Student ToC', js: true, chrome: true, new_gb_sync: true do
  include RspecJsApiHelpers
  include RspecJsCommonHelpers
  include CapybaraViewHelpers
  include GradebookEngineHelpers

  let(:program) { create(:ss_jr_program) }
  let(:school) { create(:school) }
  let(:student) { create(:student) }
  let(:instructor) { create(:instructor, schools: [school]) }
  let(:unit_1_image) { create(:media_item_image, filename: 'unit_1.png') }
  let(:unit_2_image) { create(:media_item_image, filename: 'unit_2.png') }
  let(:unit_3_image) { create(:media_item_image, filename: 'unit_3.png') }
  let(:unit_1) do
    create(:unit, media_item_id: unit_1_image.id, program: program, rank: 1)
  end
  let(:unit_2) do
    create(:unit, media_item_id: unit_2_image.id, program: program, rank: 2)
  end
  let(:unit_3) do
    create(:unit, media_item_id: unit_3_image.id, program: program, rank: 3, released: false)
  end
  let!(:lesson_1a) { create(:lesson, unit: unit_1, name: 'Lesson 1A') }
  let!(:lesson_2a) { create(:lesson, unit: unit_2, name: 'Lesson 2A') }
  let!(:lesson_3a) { create(:lesson, unit: unit_3, name: 'Lesson 3A') }
  let(:strand_1_name) { 'Strand 1' }
  let(:strand_2_name) { 'Strand 2' }
  let(:strand_1) { create(:toc_entry, title: strand_1_name) }
  let(:strand_2) { create(:toc_entry, title: strand_2_name) }
  let(:strand_1_image) { create(:media_item_image, filename: 'strand_1.png') }
  let(:strand_2_image) { create(:media_item_image, filename: 'strand_2.png') }
  let(:course) { create(:course, owner: instructor, program: program, school: school) }
  let(:section) { create(:section, instructor: instructor, course: course) }
  let(:program_logo) { create(:media_item_image, filename: 'ss_jr_logo.png') }
  let(:category) { create(:category, course: course) }
  let(:due_date_1) { Time.zone.today }
  let(:due_date_2) { 10.days.from_now.to_date }

  let(:strand_1_activity_1) do
    create(
      :activity,
      concept: concept_1,
      lesson: lesson_1a,
      toc_location: strand_1.location
    )
  end

  let(:strand_1_activity_2) do
    create(
      :activity,
      concept: concept_1,
      lesson: lesson_1a,
      toc_location: strand_1.location
    )
  end

  let(:strand_1_activity_3) do
    create(
      :activity,
      concept: concept_1,
      lesson: lesson_1a,
      toc_location: strand_1.location
    )
  end

  let(:concept_1) do
    create(
      :concept,
      id: strand_1.location,
      lesson: lesson_1a,
      media_item: strand_1_image,
      program: program,
      name: strand_1_name
    )
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

  def link_image(media_item, fixture_file)
    source_path = File.join('spec', 'fixtures', 'media_items', fixture_file)
    dest_path = media_item.full_filename
    FileUtils.makedirs(File.dirname(dest_path))
    FileUtils.cp(source_path, dest_path)
    @recycle_bin << dest_path
  end

  def toc_home_url(section_id)
    jr_section_program_content_path(
      section_id: section_id, program_id: program.id
    )
  end

  def expect_button_to(selector, action)
    expect(find(selector)['action']).to end_with(action)
  end

  def expect_to_see_list_of_strands
    within(".test-strand-id-#{strand_1.location}") do
      expect(page).to have_selector("img[src*='strand_1.png']")
      expect(page).to have_link(
        strand_1.display_name,
        href: jr_section_program_strand_path(
          id: strand_1.location, section_id: section.id, program_id: program.id
        )
      )
    end

    within(".test-strand-id-#{strand_2.location}") do
      expect(page).to have_selector("img[src*='strand_2.png']")
      expect(page).to have_link(
        strand_2.display_name,
        href: jr_section_program_strand_path(
          id: strand_2.location, section_id: section.id, program_id: program.id
        )
      )
    end
  end

  def expect_to_see_list_of_activities
    expect(page).to have_selector('h1', text: 'Lesson 1A | Strand 1')

    # Activity 1 is assigned for today but not yet opened/attempted.
    within(".test-activity-id-#{strand_1_activity_1.id}") do
      expect(page).to have_selector(
        '.test-activity-title', text: strand_1_activity_1.title
      )
      expect(page).to have_selector('.test-attempt-status', text: '')
      expect(page).to have_selector('.test-activity-due-date', text: 'Today')
    end

    # Activity 2 is assigned in the future and has been opened but not
    # completed.
    within(".test-activity-id-#{strand_1_activity_2.id}") do
      expect(page).to have_selector(
        '.test-activity-title', text: strand_1_activity_2.title
      )
      expect(page).to have_selector('.test-attempt-status', text: 'opened')
      expect(page).to have_selector(
        '.test-activity-due-date',
        text: due_date_2.strftime('%a %-m/%-d')
      )
    end

    # Activity 3 is unassigned but has been completed.
    within(".test-activity-id-#{strand_1_activity_3.id}") do
      expect(page).to have_selector(
        '.test-activity-title', text: strand_1_activity_3.title
      )
      expect(page).to have_selector('.test-attempt-status', text: 'viewed')
      expect(page).to have_selector('.test-activity-due-date', text: '')
    end
  end

  def click_return_link
    # Capybara and Selenium both rely on the headless browser (Chrome) to
    # traverse the Shadow DOM.  For simplicity's sake, JS is used to both
    # navigate to the "Return" link and trigger a click event.
    script = 'document.querySelector(".test-return-link-root")' \
             '.shadowRoot.querySelector(".test-return-link")' \
             '.click()'
    page.evaluate_script(script)
  end

  def expect_to_be_able_to_use_return_links
    purpose 'I can return from the strand show view to the list of strands' do
      click_return_link

      expect(page).to have_selector(".test-strand-id-#{strand_1.location}")
      expect(page).to have_selector(".test-strand-id-#{strand_2.location}")
    end

    purpose 'I can return from the lesson show view to the list of lessons' do
      click_return_link

      expect(page).to have_selector(".test-unit-id-#{unit_1.id}")
      expect(page).to have_selector(".test-unit-id-#{unit_2.id}")
    end

    purpose 'I can return from the lesson list view to the Content home' do
      click_return_link

      expect(page).to have_selector('title', text: 'VHL Central | Content')
      expect_url(toc_home_url(section.id))
    end
  end

  before do
    link_image(unit_1_image, 'unit_1.png')
    link_image(unit_2_image, 'unit_2.png')
    link_image(strand_1_image, 'ssjr_strand_1.png')
    link_image(strand_2_image, 'ssjr_strand_2.png')
    link_image(program_logo, 'ssjr_program_logo.png')

    lesson_1a.toc_entries = [strand_1, strand_2]
    lesson_1a.save!

    create(
      :concept,
      id: strand_2.location,
      lesson: lesson_1a,
      media_item: strand_2_image,
      program: program,
      name: strand_2_name
    )

    ProgramMediaItem.create!(
      media_item_id: program_logo.id,
      media_type: ProgramMediaItem::LOGO_MEDIA_TYPE,
      program_id: program.id
    )

    assign(strand_1_activity_1, due_date_1)
    assign(strand_1_activity_2, due_date_2)

    create(
      :attempt_opened,
      activity: strand_1_activity_2,
      section: section,
      user: student
    )

    create(
      :attempt_completed,
      activity: strand_1_activity_3,
      section: section,
      user: student
    )

    create_gradebook_engine_submission(
      activity: strand_1_activity_3,
      points_earned: strand_1_activity_3.points_possible,
      section: section,
      student: student,
      submitted_at: 5.days.ago
    )

    create(:active_enrollment, section: section, user: student)
    initialize_program_access_client_calls_for_user_and_program(student, program)
    give_user_access_to_program(student, program)
    log_in_as(student)
  end

  scenario 'As a student, I can drill down from a list of visible units/lessons, to ' \
           'a list of strands, to a list of activities per strand' do
    purpose 'In a Lesson (1-Tier) program, I can see a list of lessons' do
      visit toc_home_url(section.id)

      click_link_or_button('Activities')

      expect(page).not_to have_selector(".test-unit-id-#{unit_3.id}")

      within(".test-unit-id-#{unit_1.id}") do
        expect(page).to have_selector("img[src*='unit_1.png']")

        href = jr_section_program_lesson_path(
          id: lesson_1a.id,
          section_id: section.id,
          program_id: program.id
        )
        expect(page).to have_selector("a[href='#{href}']")
      end

      within(".test-unit-id-#{unit_2.id}") do
        expect(page).to have_selector("img[src*='unit_2.png']")

        href = jr_section_program_lesson_path(
          id: lesson_2a.id,
          section_id: section.id,
          program_id: program.id
        )
        expect(page).to have_selector("a[href='#{href}']")
      end

      purpose 'I can click into a lesson to see a list of strands' do
        click_link_or_button(unit_1.display_name)

        expect_to_see_list_of_strands
      end

      purpose 'I can click a strand to see a list of activities' do
        click_link_or_button(strand_1.display_name)

        expect_to_see_list_of_activities
      end

      expect_to_be_able_to_use_return_links
    end

    purpose 'In a Unit and Lesson (2-Tier) program, I can see a list of ' \
            'the visible units with their lessons' do
      unit_1.update!(name: 'Unit 1')
      unit_2.update!(name: 'Unit 2')
      unit_3.update!(name: 'Unreleased Unit 3')
      lesson_1b = create(:lesson, unit: unit_1, rank: 2, name: 'Lesson 1B')
      lesson_2b = create(:lesson, unit: unit_2, rank: 2, name: 'Lesson 2B')

      visit toc_home_url(section.id)

      click_link_or_button('Activities')

      expect(page).not_to have_selector(".test-unit-id-#{unit_3.id}")

      within(".test-unit-id-#{unit_1.id}") do
        expect(page).to have_selector("img[src*='unit_1.png']")
        expect(page).to have_selector('.test-unit-label', text: unit_1.display_name)
        expect(page).to have_link(
          lesson_1a.display_name,
          href: jr_section_program_lesson_path(
            id: lesson_1a.id, section_id: section.id, program_id: program.id
          )
        )
        expect(page).to have_link(
          lesson_1b.display_name,
          href: jr_section_program_lesson_path(
            id: lesson_1b.id, section_id: section.id, program_id: program.id
          )
        )
      end

      within(".test-unit-id-#{unit_2.id}") do
        expect(page).to have_selector("img[src*='unit_2.png']")
        expect(page).to have_selector('.test-unit-label', text: unit_2.display_name)
        expect(page).to have_link(
          lesson_2a.display_name,
          href: jr_section_program_lesson_path(
            id: lesson_2a.id, section_id: section.id, program_id: program.id
          )
        )
        expect(page).to have_link(
          lesson_2b.display_name,
          href: jr_section_program_lesson_path(
            id: lesson_2b.id, section_id: section.id, program_id: program.id
          )
        )
      end

      purpose 'I can click into a lesson to see a list of strands' do
        click_link(lesson_1a.display_name)

        expect_to_see_list_of_strands
      end

      purpose 'I can click a strand to see a list of activities' do
        click_link(strand_1.display_name)

        expect_to_see_list_of_activities
      end

      expect_to_be_able_to_use_return_links
    end
  end
end
