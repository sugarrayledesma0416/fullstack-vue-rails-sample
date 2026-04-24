feature 'Supersite Junior Student Navigation', js: true, chrome: true do
  include RspecJsApiHelpers
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include CapybaraViewHelpers

  # Need to specify the time to avoid intermittent date-based failures
  # with the display of worksets on the Calendar. Without this, assignments
  # due on future dates won't show up in the initial calendar view (which
  # is for the current month) when the tests run on the last day of the
  # month.
  let(:today) { Date.civil(2020, 11, 1) }

  let(:program) { create(:program_with_toc_entries, family: 'supersites_jr') }
  let(:alternate_program) { create(:program_with_toc_entries, family: 'supersites_jr') }
  let(:school) { create(:school) }
  let(:student) { create(:student) }
  let(:instructor) { create(:instructor, schools: [school]) }
  let(:unit_1) { program.units.first }
  let(:unit_2) { program.units.second }
  let(:lesson) { unit_1.lessons.first }

  let(:course) do
    create(
      :course,
      end_date: (today + 6.months),
      allow_past_end_date: true,
      first_unit_id: unit_1.id,
      last_unit_id: program.units.last.id,
      owner: instructor,
      program: program,
      school: school,
      start_date: (today - 1.month)
    )
  end

  let(:category_name) { 'Homework' }
  let(:category) { create(:category, course: course, name: category_name) }
  let(:section) { create(:section, instructor: instructor, course: course) }
  let(:program_logo) { create(:media_item_image, filename: 'ss_jr_logo.png') }
  let(:strand) { create(:toc_entry) }

  let(:concept) do
    create(
      :concept,
      id: strand.location,
      lesson: lesson
    )
  end

  let(:activity) { create(:activity, concept: concept, lesson: lesson) }
  let(:grownups_nav_label) { 'Grown-ups' }
  let(:grownups_page_title) { 'Welcome to the School-Home Connection' }

  def link_image(media_item, fixture_file)
    source_path = File.join('spec', 'fixtures', 'media_items', fixture_file)
    dest_path = media_item.full_filename
    FileUtils.makedirs(File.dirname(dest_path))
    FileUtils.cp(source_path, dest_path)
    @recycle_bin << dest_path
  end

  def student_dashboard_url
    jr_course_section_path(course_id: course.id, section_id: section.id)
  end

  def toc_home_url(section_id)
    jr_section_program_content_path(
      section_id: section_id, program_id: program.id
    )
  end

  def expect_to_see_supersite_junior_navigation
    expect(page).to have_selector('.test-supersite-junior-program-nav')
  end

  before do
    link_image(program_logo, 'ssjr_program_logo.png')
    ProgramMediaItem.create!(
      media_item_id: program_logo.id,
      media_type: ProgramMediaItem::LOGO_MEDIA_TYPE,
      program_id: program.id
    )
    allow(AvatarService::Avatar).to receive(:new).and_return(
      instance_double(AvatarService::Avatar, upload_exists?: false, image_url: '', thumb_url: '')
    )

    initialize_program_access_client_calls_for_user_and_program(student, program)
    give_user_access_to_program(student, program)
    log_in_as(student)
    create_activity_with_unit_lesson_and_concept(program, points_possible: 10)
    create(
      :assignment,
      assignable: activity,
      category: category,
      due_date: today + 1.day,
      section: section
    )
  end

  scenario 'As a student, I can navigate among the dashboard, content, ' \
           'progress and grown-ups home pages', new_gb_sync: true do
    Timecop.freeze(today) do
      purpose 'When not enrolled in a section, the only navigation element ' \
              'I can see is to Content' do
        visit toc_home_url(0)

        expect(page).to have_link('Content')
        expect(page).not_to have_link('Dashboard')
        expect(page).not_to have_link('Progress')
        expect(page).not_to have_link(grownups_nav_label)
      end

      purpose 'I can use the program logo to get back to the Content page' do
        page.find('.test-program-logo').click
        expect(page).to have_selector('.test-toc-activities-clickee', text: 'Activities')
        expect_url(toc_home_url(0))
      end

      create(:active_enrollment, section: section, user: student)

      purpose 'I can view the student dashboard' do
        visit student_dashboard_url
        expect(page).to have_selector('h1', text: "Hi, #{student.first_name}!")
      end

      purpose 'I can navigate to the content page' do
        click_link('Content')
        expect_url(toc_home_url(section.id))
      end

      purpose 'I see appropriate buttons and copy depending on state' do
        # Activities button should appear normal if program has activities
        expect(page).to have_selector('.test-toc-activities-clickee', text: 'Activities')

        # Assessment button should appear normal if section + assessments exist
        expect(page).to have_selector('.test-toc-assessments-clickee', text: 'Assessments')


        # Vocab tools, vText, and eBook should not appear
        expect(page).not_to have_selector('.test-toc-vtext-clickee')
        expect(page).not_to have_selector('.test-toc-ebook-clickee')
        expect(page).not_to have_selector('.test-toc-vocab-tools-clickee')

        # Change state and refresh page
        program_config = ProgramConfig.new(
          created_at: Time.now,
          creator_id: instructor.id,
          ebook: '',
          vocab_tools: '',
          vtext_label: '',
          program_id: program.id
        )
        program_config.save!

        allow_any_instance_of(AccessGuardian).to receive(:has_vocab_tools?).and_return(true)
        allow_any_instance_of(VtextLinker).to receive(:menu_linkable?).and_return(true)
        allow_any_instance_of(AccessGuardian).to receive(:has_ebook?).and_return(true)

        visit student_dashboard_url
        click_link('Content')
        expect_url(toc_home_url(section.id))

        # TODO: uncomment once Vocab Tools is no longer temporarily hidden.
        ## Vocab tools should appear, with "Vocabulary Tools" as label
        #expect(page).to have_selector('.test-toc-vocab-tools-clickee', text: 'Vocabulary Tools')

        # vText should appear, with "vText" as label
        expect(page).to have_selector('.test-toc-vtext-clickee', text: 'vText')

        # eBook should appear, with "eBook" as label
        expect(page).to have_selector('.test-toc-ebook-clickee', text: 'eBook')

        # Override default labels and refresh page
        program_config = ProgramConfig.new(
          created_at: Time.now + 1.second,
          creator_id: instructor.id,
          ebook: 'eeeeeeeeeeBook',
          vocab_tools: 'My Vocabulary',
          vtext_label: 'vvvvvvvvvvText',
          program_id: program.id,
          content_menu_additional_entries: [
            { label: 'Student vText alternate program', url: 'http://student.com', target_user: 'Student', program_id: alternate_program.id },
            { label: 'Instructor vText alternate program', url: 'http://instructor.com', target_user: 'Instructor', program_id: alternate_program.id }
          ]
        )
        program_config.save!

        visit student_dashboard_url
        click_link('Content')
        expect_url(toc_home_url(section.id))

        # Additional entries to programs with no vText included in the user licenses should not show
        expect(page).not_to have_selector('.test-toc-add-entry-clickee', text: 'Student vText alternate program')

        # Simulate user license
        allow_any_instance_of(AccessGuardian).to receive(:has_vtext?)
          .with(alternate_program.id)
          .and_return(true)

        visit student_dashboard_url
        click_link('Content')

        # Additional entries to programs with vText included in the user licenses should show
        expect(page).to have_selector('.test-toc-add-entry-clickee', text: 'Student vText alternate program')

        # TODO: uncomment once Vocab Tools is no longer temporarily hidden.
        ## Labels should be overridden
        #expect(page).to have_selector('.test-toc-vocab-tools-clickee', text: 'My Vocabulary')

        # vText should appear, with "vvvvvvvvvvText" as label
        expect(page).to have_selector('.test-toc-vtext-clickee', text: 'vvvvvvvvvvText')

        # eBook should appear, with "eeeeeeeeeeBook" as label
        expect(page).to have_selector('.test-toc-ebook-clickee', text: 'eeeeeeeeeeBook')
      end

      purpose 'I can navigate to the progress page' do
        click_link('Progress')
        expect(page).to have_selector('h1', text: 'Progress')
      end

      purpose 'I can navigate to the grownups page' do
        click_link(grownups_nav_label)
        expect(page).to have_selector('h1', text: grownups_page_title)
        expect(page).to have_link('Accessibility Features')
      end

      purpose 'I can use the program logo to get back to the SS Jr. dashboard' do
        page.find('.test-program-logo').click
        expect(page).to have_selector('h1', text: "Hi, #{student.first_name}!")
        expect_url(student_dashboard_url)
      end

      announcement_1_title = 'Title 1'
      announcement_2_title = 'Title 2'

      purpose 'I can navigate the sub-sections of the Grownups area' do
        announcement_1 = create(
          :announcement,
          author: instructor,
          title: announcement_1_title,
          announcement_sections_attributes: [section: section]
        )
        announcement_2 = create(
          :announcement,
          author: instructor,
          title: announcement_2_title,
          announcement_sections_attributes: [section: section]
        )
        announcement_2.notifications.first.dismiss

        click_link(grownups_nav_label)

        expect(page).to have_selector('h1', text: grownups_page_title)

        target_id = announcement_1.notifications.first.id

        within(".test-notification-#{target_id}") do
          expect(page).to have_selector(
            '.test-notification-label',
            text: announcement_1_title
          )
        end

        purpose 'I can see a list of previously viewed announcements' do
          within('.test-announcements-panel') do
            click_link('Viewed')
          end

          target_id = announcement_2.notifications.first.id

          within(".test-notification-#{target_id}") do
            expect(page).to have_selector(
              '.test-notification-label',
              text: announcement_2_title
            )
          end
        end

        purpose 'I can navigate to the Calendar' do
          click_link('Calendar')

          expect(page).to have_selector('h1', text: 'Calendar')

          purpose 'The worksets are shown for each day, but are not clickable' do
            workset_label = "#{category_name} (1)"
            expect(page).to have_text(workset_label)
            expect(page).not_to have_link(workset_label)
          end

          purpose 'I can navigate among months' do
            find('.test-next-month-button').click
            expect(page).to have_text('DECEMBER 2020')

            find('.test-prev-month-button').click
            expect(page).to have_text('NOVEMBER 2020')
          end
        end

        purpose 'I can navigate to Grades' do
          click_link('Grades')

          expect(page).to have_selector('.c-subnav__context', text: 'Grades')
        end

        component = create(:resource_component, program: program)
        resource_1 = create(
          :resource,
          program: program,
          protected: false,
          resource_component: component,
          start_unit_id: unit_1.id,
          vhl_student_resource: true
        )

        resource_2 = create(
          :resource,
          program: program,
          protected: false,
          resource_component: component,
          start_unit_id: unit_2.id,
          vhl_student_resource: true
        )

        purpose 'I can navigate to the Resources' do
          click_link('Resources')

          expect(page).to have_selector('h1', text: 'Resources')

          step 'Verify the correct content is shown' do
            expect(page).to have_selector(
              '.test-resources-header',
              text: "#{unit_1.display_name} | All Components"
            )
            expect(page).to have_link(resource_1.title)
            expect_to_see_supersite_junior_navigation
          end

          click_link(component.name)

          step 'Verify the correct content is shown' do
            expect(page).to have_selector(
              '.test-resources-header',
              text: "#{unit_1.display_name} | #{component.name}"
            )
            expect(page).to have_link(resource_1.title)
            expect_to_see_supersite_junior_navigation
          end

          click_link('All Components')

          step 'Verify the correct content is shown' do
            expect(page).to have_selector(
              '.test-resources-header',
              text: "#{unit_1.display_name} | All Components"
            )
            expect(page).to have_link(resource_1.title)
            expect_to_see_supersite_junior_navigation
          end

          select(unit_2.display_name, from: :browse_by_unit)

          step 'Verify the correct content is shown' do
            expect(page).to have_selector(
              '.test-resources-header',
              text: "#{unit_2.display_name} | All Components"
            )
            expect(page).to have_link(resource_2.title)
            expect_to_see_supersite_junior_navigation
          end
        end
      end
    end
  end
end
