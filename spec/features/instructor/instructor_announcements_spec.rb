feature 'Announcements', js: true, chrome: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include ActivityTest::Helpers
  include WaitForNextPage

  let(:school) { create(:school) }
  let(:instructor) { create(:instructor, schools: [school]) }
  let(:program) { create(:program) }

  def expect_flash(type, message)
    flash = find(".test-flash-#{type}")
    expect(flash).to be_visible
    expect(flash).to have_text(message)
  end

  def create_announcement_selector(announcement_id)
    "[data-announcement-id='#{announcement_id}']"
  end

  before do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  scenario 'As an instructor, I can create different announcements' do
    no_announcement_message = 'You have no announcements.'
    save_button_label = 'Save'
    cancel_button_label = 'cancel'
    create_announcement = 'Create announcement'
    date_picker_name = 'announcement_show_on'
    date_field_label = 'Show announcement on calendar (optional)'
    new_title = 'New Title'
    original_title = 'Original Title'
    edited_title = 'Edited Title'
    title_field_label = 'Title'
    cancel_class_label = 'Cancel Class'
    link_title_field_label = 'Link title'
    link_url_field_label = 'Link URL'
    announcement_id = ''
    original_announcement_text = 'Original Announcement Text'
    edited_announcement_text = 'Edited Announcement Text'
    original_title_url = 'https://www.vhlcentral.com'
    modified_title_url = 'http://www.vhlcentral.com'
    original_title_link_text = 'vhlcentral page'
    modified_title_link_text = 'vhlcentral modified page'
    modified_date = '2018-04-28'

    purpose 'I can navigate to the announcements index page' do
      step 'Go to the announcements index page' do
        visit instructor_announcements_path(program)
      end
      step 'Check if the page structure is complete' do
        expect(page).to have_selector('#column_wrapper')
        expect(page).to have_selector('h1', text: 'Announcements')
        expect(page).to have_text(create_announcement)
        expect(page).to have_selector('h3', text: no_announcement_message)
      end
      step 'The announcement page displays no announcement' do
        expect(page).to have_text(no_announcement_message)
      end
    end

    purpose 'I can create an announcement only when there is a Course with at least one section' do
      step 'There is no link to create a new announcement' do
        expect(page).to have_no_link(create_announcement)
      end
      step 'Create a course record for this instructor' do
        create_course
      end
      page.refresh
      step 'Verify that the link to create a new announcement is disabled' do
        expect(page).to have_no_link(create_announcement)
      end
    end

    purpose 'I can only create an announcement if I have at least one section' do
      step 'I see text Create Announcement that is not a clickable link' do
        expect(page).to have_no_link(create_announcement)
      end
      step 'Create a section in the course' do
        @section = create(:section, course: @course, instructor: instructor)
      end
      page.refresh
      step 'Verify that the link to create a new announcement is enabled' do
        expect(page).to have_link(create_announcement)
      end
    end

    purpose 'When creating an announcement I can cancel the procedure' do
      step 'Click on the link to create a new announcement' do
        click_link(create_announcement)
      end
      step 'Add a title' do
        fill_in(title_field_label, with: original_title)
      end
      step 'Click the cancel button and accept the confirmation that pops up.' do
        if ENV['NO_CHROME_UNLOAD'] == 'true'
          click_link(cancel_button_label)
        else
          accept_alert do
            click_link(cancel_button_label)
          end
        end
      end
      step 'The announcement page displays no announcement' do
        expect(page).to have_text(no_announcement_message)
      end
    end

    purpose 'When creating an announcement only a title is required' do
      step 'Click on the link to create a new announcement' do
        click_link(create_announcement)
      end
      click_button(save_button_label)
      step 'I see an error message saying that a title is required' do
        expect(page).to have_selector(
          '.c-message--error li',
          text: 'Title is required'
        )
      end
      step 'Add a title' do
        fill_in(title_field_label, with: original_title)
      end

      click_button(save_button_label)

      wait_for_selector('h1', text: 'Announcements')

      announcement_id = Announcement.last.id
      step 'I see a success message' do
        expect_flash('notice', 'The announcement was successfully created.')
      end
      step 'The announcement page displays the announcement' do
        expect_page_to_display_announcement(
          id: announcement_id, title: original_title
        )
      end
    end

    purpose 'When editing an announcement I can fill optional fields' do
      announcement_text = ''
      step 'Click on the edit button of the announcement' do
        click_link('edit')
      end
      purpose 'I can use the accent bar' do
        step 'click all buttons in lower case' do
          find('#announcement_body').click
          first_accent_bar = AccentBar.characters('es')[0].first
          click_button(first_accent_bar)
          click_button(first_accent_bar)
          announcement_text << first_accent_bar
        end
        step 'the announcement text contains all the characters clicked' do
          expect(find_field('Announcement text').value).to eq announcement_text
        end
      end
      step 'Set an announcement text' do
        fill_in('Announcement text', with: original_announcement_text)
      end
      purpose 'I can cancel class only when announcement date is set' do
        step 'Initially cancel class checkbox is disabled' do
          expect(page).to have_field(cancel_class_label, disabled: true)
        end
        step 'Select an announcement date' do
          # close the accent bar
          find('.test-close-accent-bar-modal').click
          find_by_id(date_picker_name).click
          find('span', text: /\ANext\z/).click
          find('.ui-state-default', text: '22').click
        end
        step 'Cancel class checkbox is enabled' do
          expect(page).to have_field(cancel_class_label, disabled: false)
        end
        step 'Cancel class is disabled when announcement date is removed' do
          fill_in(date_picker_name, with: '')
          expect(page).to have_field(cancel_class_label, disabled: true)
        end
      end
      purpose 'Select an announcement date' do
        step 'Error message is displayed and cancel class checkbox is disabled when date is entered in unsupported format' do
          fill_in(date_picker_name, with: '02-04-96')
          page.find('body').click
          expect(page).to have_selector('.test-calendar-error-label', visible: true)
          expect(page).to have_field(cancel_class_label, disabled: true)
        end

        step 'No error message is displayed and cancel class is enabled when date is entered in supported format' do
          date = Time.now.to_date
          expected_date = date.strftime('%Y/%m/22')
          fill_in(date_picker_name, with: expected_date)
          page.find('body').click
          expect(page).to have_selector('.test-calendar-error-label', visible: false)
          expect(page).to have_field(cancel_class_label, disabled: true)
        end

        step 'Date could be selected using datepicker' do
          find_by_id(date_picker_name).click
          find('span', text: /\ANext\z/).click
          find('.ui-state-default', text: '22').click
          expect(page).to have_selector('.test-calendar-error-label', visible: false)
        end
      end
      step 'Set Cancel class checkbox' do
        vhl_check(cancel_class_label)
      end
      step 'Add a link title' do
        fill_in(link_title_field_label, with: original_title_link_text)
      end
      step 'Add a link URL' do
        fill_in(link_url_field_label, with: original_title_url)
      end
      step 'Choose a file' do
        attach_file('uploaded_file', Rails.root.join('public', 'images', 'VHLlogo.jpg'))
      end
      click_button(save_button_label)
      step 'I see a success message' do
        expect_flash('notice', 'The announcement was successfully modified.')
      end
      step 'The announcement page displays the announcement correctly' do
        expect_page_to_display_announcement(
          id: announcement_id,
          title: original_title,
          body: original_announcement_text,
          file: 'VHLlogo.jpg',
          is_class_cancelled: true
        )
      end
    end

    purpose 'When editing an announcement the form is filled with saved information' do
      step('Click on the edit button of announcement') { click_link('edit') }
      step 'The title is set' do
        expect(page).to have_field(title_field_label, with: original_title)
      end
      step 'The announcement text is set' do
        expect(find_field('Announcement text').value).to eq original_announcement_text
      end
      step 'The date is set' do
        date = Time.now.to_date + 1.months
        expected_date = date.strftime('%Y-%m-22')
        expect(page).to have_field(date_field_label, with: expected_date)
      end
      step 'Cancel class is set' do
        expect(page).to have_field(cancel_class_label, checked: true)
      end
      step 'The link title is set' do
        expect(page).to have_field(link_title_field_label, with: original_title_link_text)
      end
      step 'The link URL is set' do
        expect(page).to have_field(link_url_field_label, with: original_title_url)
      end
    end

    purpose 'When editing an announcement, modifications are saved' do
      step 'Edit the announcement' do
        fill_in(title_field_label, with: edited_title)
        fill_in('Announcement text', with: edited_announcement_text)
        vhl_uncheck(cancel_class_label)
        fill_in(date_field_label,
                with: I18n.l(Date.new(2018, 4, 28), format: '%m/%d/%Y'))
        fill_in(link_title_field_label, with: modified_title_link_text)
        fill_in(link_url_field_label, with: modified_title_url)
        attach_file('uploaded_file', Rails.root.join('public', 'images', 'audio_old.gif'))
      end
      click_button(save_button_label)
      step 'I see a success message' do
        expect_flash('notice', 'The announcement was successfully modified.')
      end
      step 'The announcement page displays the announcement correctly' do
        expect_page_to_display_announcement(
          id: announcement_id,
          title: edited_title,
          body: edited_announcement_text,
          file: 'audio_old.gif'
        )
      end
      click_link('edit')
      step 'I see that the updated announcement is set' do
        expect(page).to have_field(title_field_label, with: edited_title)
        expect(find_field('Announcement text').value).to eq edited_announcement_text
        expect(page).to have_field(date_field_label, with: modified_date)
        expect(page).to have_field(cancel_class_label, checked: false)
        expect(page).to have_field(link_title_field_label, with: modified_title_link_text)
        expect(page).to have_field(link_url_field_label, with: modified_title_url)
      end
    end

    purpose 'When editing an announcement I can cancel the procedure' do
      step 'Set a new title' do
        fill_in(title_field_label, with: new_title)
      end
      step 'Click the cancel button and accept the confirmation that pops up.' do
        if ENV['NO_CHROME_UNLOAD'] == 'true'
          click_link(cancel_button_label)
        else
          accept_alert do
            click_link(cancel_button_label)
          end
        end
      end
      step 'The announcement page displays the previously saved announcement' do
        expect_page_to_display_announcement(
          id: announcement_id,
          title: edited_title,
          body: edited_announcement_text,
          file: 'audio_old.gif'
        )
      end
    end

    purpose 'Harmful field texts are escaped' do
      # The variables starting with prefix harmful are used for script injection
      # and the variable started with escape prefix are used for validating
      # escaped string. The two different kind of prefix is used for ease of
      # understanding
      window_close_script = 'window.close();'
      harmful_text = '<script>' + window_close_script + '</script>'
      harmful_title = harmful_text + new_title
      escaped_title = harmful_title
      harmful_announcement_text = harmful_text + edited_announcement_text
      harmful_link_title = harmful_text + modified_title_link_text
      escaped_linked_title = harmful_link_title
      sanitized_announcement_text = window_close_script + edited_announcement_text

      click_link('edit')
      step 'Set announcement title with script injection' do
        fill_in(title_field_label, with: harmful_title)
      end
      step 'Set an announcement text containing script injection' do
        fill_in('Announcement text', with: harmful_announcement_text)
      end
      step 'Set link title with script injection' do
        fill_in(link_title_field_label, with: harmful_link_title)
      end
      click_button('Save')
      step 'The announcement title escapes the script tags' do
        within(page.find(create_announcement_selector(announcement_id))) do
          title_element = find('[data-content-type="announcement_title"]')
          # There is no <script> tag rendered as html
          expect(title_element).to have_no_selector('script')
          # The <script> tag is safely rendered as harmless text, with the
          # open/close tag
          expect(title_element).to have_text(escaped_title)
        end
      end
      step 'The announcement text has been sanitized' do
        within(page.find(create_announcement_selector(announcement_id))) do
          # There is no <script> tag rendered as html
          expect(page).to have_no_selector('script')
          # checking for have_text as text sanitization removes scripts tag
          # and add multiple p tags.
          expect(page).to have_text(sanitized_announcement_text)
        end
      end
      step 'visit announcement details page' do
        visit(section_announcement_path(@section.id, announcement_id))
      end
      within(page.find(".test-announcement-#{announcement_id}")) do
        step 'Title is set is escaped' do
          expect(page).to have_selector('.test-announcement-title', text: escaped_title)
          expect(page.find('.test-announcement-title')).to have_no_selector('script')
        end
        step 'Announcement text is sanitized' do
          # The <script> tag is removed and renderred as harmless text
          expect(page.find('p').text).to eq sanitized_announcement_text
          # There is no <script> tag rendered as html
          within(page.find('[data-content-type="announcement_body"')) do
            expect(page).to have_no_selector('script')
          end
        end
        step 'Link Title text is escaped' do
          # The <script> tag is safely rendered as harmless text, with the
          # open/close tag
          expect(page).to have_selector(
            '[data-content-type="announcement_external_link"]',
            text: escaped_linked_title
          )
          # There is no <script> tag rendered as html
          within(page.find('[data-content-type= "announcement_external_link"]')) do
            expect(page).to have_no_selector('script')
          end
        end
      end
    end

    purpose 'I can delete an announcement' do
      visit instructor_announcements_path(program)
      click_link('edit')
      step 'Click on the delete button'
      step 'An alert with text "Are you sure you want to delete this announcement?" is displayed'
      step 'Confirm' do
        accept_confirm do
          click_link('delete')
        end
      end
      step 'The announcement page displays no announcement' do
        expect(page).to have_text(no_announcement_message)
      end
    end
  end

  def create_course
    @course ||= create(:course, owner: instructor, program: program, school: school)
  end

  def expect_page_to_display_announcement(id:, title:, body: '', file: nil, is_class_cancelled: false)
    within(page.find(create_announcement_selector(id))) do
      expect(page).to have_selector('span[data-content-type="announcement_title"]', text: title)
      expect(page).to have_selector(".test-class-cancelled") if is_class_cancelled
      expect(page).not_to have_selector(".test-class-cancelled") if !is_class_cancelled
      expect(page).to have_link('edit')
      expect(page).to have_text(body)
      if file
        expect(page).to have_selector(
          'p[data-content-type="announcement_download_link"] ' \
          "a[href='#{download_announcement_attachment_path(@section, id)}']"
        )
      else
        expect(page).to have_no_selector(
          'p[data-content-type="announcement_download_link"]'
        )
      end
    end
  end
end
