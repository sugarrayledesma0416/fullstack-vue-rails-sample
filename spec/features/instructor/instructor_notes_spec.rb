feature 'Instructor Notes', js: true, chrome: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:vol_program_with_lessons) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:note_selector) { '[data-content-type="instructor_activity_note"]' }
  let(:body_text_selector) { '[data-content-type="note_body_text"]' }
  let(:activity) { create_fill_in_the_blanks_activity_with_model(program) }

  def create_audio_note(note_type, body_text = 'Test instructor note')
    create(
      :activity_note,
      activity: activity,
      body_text: body_text,
      instructor: instructor,
      note_item_id: 'reference_01',
      note_type: note_type,
      program: program,
      recording: create(:recording)
    )
  end

  def edit_note(note_container)
    edit_link = note_container.find('.test-edit-note')
    edit_link.click
  end

  def delete_note(note_container)
    delete_link = note_container.find('.test-delete-note')
    accept_alert do
      delete_link.click
    end
  end

  def drag_modal_to_top_of_page
    # Setting css.top to 0 currently moves the modal partially outside of the screen.
    # So this method is just a no-op for now.
    # If the forthcoming changes to JqueryUi break this spec again, uncomment the
    # following line.
    # execute_script('$(".ui-dialog").css({"top": "0"})')
  end

  def submit_note
    within '.test-instructor-note-modal' do
      click_button 'Submit'
    end
  end

  def confirm_flash_banner_appearance
    within '.test-instructor-note-flash-banner' do
      expect(page).to have_text('Choose the selectable area to add your Instructor Note.')
      expect(page).to have_text('CANCEL INSTRUCTOR NOTE')
    end
  end

  def cancel_flash_banner
    find(".test-instructor-note-cancel").click
  end

  def confirm_modal_appearance
    within '.test-instructor-note-modal' do
      expect(find_by_id('cke_current_note_body_text')).to be_visible
      expect(page.has_checked_field? 'note_type_expanded').to have_text(true)

      # Expect to have audio controls
      audio_controls = find('.test-instructor-note-audio-controls')
      audio_controls_should_be_visible(audio_controls)

      expect(page).to have_button('Cancel')
      expect(page).to have_button('Submit', disabled: true)
    end
  end

  before do
    # Stub pubnub requests
    stub_request(:get, %r{^https://ps.pndsn.com/*})
      .to_return(status: 200, body: '', headers: {})
  end

  context 'instructor creates the note' do
    before do
      initialize_program_access_client_calls_for_user_and_program(
        instructor,
        program
      )
      log_in_as(instructor)
    end

    scenario 'Instructor adds an "Expand by default" note' do
      visit section_activity_path(0, activity)

      # Add a note
      click_link_or_button 'Add instructor note'
      confirm_flash_banner_appearance
      cancel_flash_banner

      # Get notable elements
      notable_elements = all('[data-instructor-notable]')
      expect(notable_elements).not_to be_empty

      # All notable elements should not be highlighted
      notable_elements.each do |element|
        expect(element[:class]).not_to include('highlighted_notable')
      end
      click_link_or_button 'Add instructor note'

      # All notable elements should get highlighted
      notable_elements.each do |element|
        expect(element[:class]).to include('highlighted_notable')
      end

      # Click the higlighted model reference
      find_by_id('overlay-reference_01').click
      confirm_modal_appearance

      # Now we should see the ckeditor dialog
      ckeditor = find_by_id('cke_current_note_body_text')
      expect(ckeditor).to be_visible

      fill_in_ckeditor('current_note_body_text', 'Test instructor note')
      page.find('label[for="note_type_expanded"]').click
      submit_note

      expect(
        find('.test-flash-banner--success')
      ).to have_text('Note successfully saved!')

      # Notable elements should not be highlighted anymore
      notable_elements.each do |element|
        expect(element[:class]).not_to include('highlighted_notable')
      end
      instructor_note = find(note_selector)
      expect(instructor_note.find(body_text_selector)).to have_text('Test instructor note')
      expect(ActivityNote.first).to have_attributes(
        note_type: 'expanded',
        note_item_id: 'reference_01'
      )
    end

    scenario 'Instructor adds an "Minimized by default" note' do
      visit section_activity_path(0, activity)
      click_link_or_button 'Add instructor note'
      confirm_flash_banner_appearance

      notable_elements = all('[data-instructor-notable]')
      expect(notable_elements).not_to be_empty

      notable_elements.each do |element|
        expect(element[:class]).to include('highlighted_notable')
      end

      find_by_id('overlay-reference_01').click
      confirm_modal_appearance
      fill_in_ckeditor('current_note_body_text', 'Test instructor note')
      page.find('label[for="note_type_collapsed"]').click
      submit_note

      expect(
        find('.test-flash-banner--success')
      ).to have_text('Note successfully saved!')

      notable_elements.each do |element|
        expect(element[:class]).not_to include('highlighted_notable')
      end

      instructor_note = find(note_selector)
      instructor_note.click
      expect(instructor_note.find(body_text_selector)).to have_text('Test instructor note')

      expect(ActivityNote.first).to have_attributes(
        note_type: 'collapsed',
        note_item_id: 'reference_01'
      )
    end

    scenario 'Instructor edits a note for an activity' do
      old_note = create(
        :activity_note,
        activity: activity,
        program: program,
        body_text: 'Test instructor note',
        instructor: instructor,
        note_item_id: 'reference_01',
        note_type: 'expanded'
      )
      visit section_activity_path(0, activity)

      # The note should exist
      instructor_note = find(note_selector)
      body_text_node = instructor_note.find(body_text_selector)
      expect(body_text_node).to have_text('Test instructor note')

      edit_note(instructor_note)

      # Now we should see the ckeditor dialog
      ckeditor = find_by_id('cke_current_note_body_text')
      expect(ckeditor).to be_visible

      # Edit the note
      drag_modal_to_top_of_page
      fill_in_ckeditor('current_note_body_text', 'def')
      submit_note

      # We should see a success message
      expect(
        find('.test-flash-banner--success')
      ).to have_text('Note successfully saved!')

      # The note should have been updated
      within note_selector do
        expect(page).to have_selector(body_text_selector, text: 'def')
      end

      # Ensure saved note persists in database
      old_note.reload
      expect(old_note.body_text).to match(/def/)
    end

    scenario 'Instructor deletes a note for an activity' do
      create_audio_note('expanded')
      visit section_activity_path(0, activity)

      # The note should exist
      instructor_note = find(note_selector)
      body_text_node = instructor_note.find(body_text_selector)
      expect(body_text_node).to have_text('Test instructor note')

      delete_note(instructor_note)

      # We should see a success message
      expect(
        find('.test-flash-banner--success')
      ).to have_text('Note successfully removed!')

      # The note should not exist anymore
      expect(page).to have_no_selector(note_selector)
    end

    scenario 'Instructor views previously created "sidebar" and "inline" notes' do
      create_audio_note('inline', 'Inline Note: dummy body text.')
      create_audio_note('sidebar', 'Sidebar Note: dummy body text.')
      visit section_activity_path(0, activity)

      # Inline Note now expand by default, hence body_text should be visible.
      expect(page).to have_text('Inline Note: dummy body text.')

      # Sidebar Note now collapse by default, hence body_text should not be visible.
      expect(page).not_to have_text('Sidebar Note: dummy body text.')
    end

    scenario 'Instructor adds an audio note for an activity' do
      visit section_activity_path(0, activity)

      # Add a note
      click_link_or_button 'Add instructor note'

      # Click the higlighted model reference
      find_by_id('overlay-reference_01').click
      drag_modal_to_top_of_page

      # Audio activity recorder should be visible
      audio_controls = find('.test-instructor-note-audio-controls')
      audio_controls_should_be_visible(audio_controls)
    end

    scenario 'Instructor replaces an existing audio note' do
      create_audio_note('expanded')
      visit section_activity_path(0, activity)

      instructor_note = find(note_selector)
      edit_note(instructor_note)
      drag_modal_to_top_of_page

      # Audio activity recorder should be visible
      audio_controls = find('.test-instructor-note-audio-controls')
      audio_controls_should_be_visible(audio_controls)
    end

    def audio_controls_should_be_visible(audio_controls)
      expect(audio_controls).to be_visible
      expect(audio_controls.find('.test-instructor-note-audio-player')).to be_visible
      expect(audio_controls.find('.test-instructor-note-audio-recorder')).to be_visible
    end
  end

  scenario 'Student listens to a recording that a instructor has created', new_gb_sync: true do
    give_user_access_to_program(student, program)
    Enrollment.create(user: student, section: section)
    log_in_as(student)
    create_audio_note('expanded')
    visit section_activity_path(section.id,  activity)
    # Audio activity player should be visible
    expect(find('.test-note-player')).to be_visible
  end
end
