feature 'Resources', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include ActivityTest::Helpers
  include RspecJsDownloadHelpers

  def expect_404
    expect(page.server.error.class).to eq(ActiveRecord::RecordNotFound)
    page.server.reset_error!
  end

  def expect_redirection_to_ua(unauthorized_program)
    url = CGI.unescape(page.current_url)
    expect(url.start_with?(UA_URL) &&
           url.include?("/access_problem/#{unauthorized_program.id}")).to be_truthy
  end

  def expect_error(message)
    expect(page).to have_selector('.c-message--error li', text: message)
  end

  def expect_flash(type, message)
    flash = find(".test-flash-#{type}")
    expect(flash).to be_visible
    expect(flash).to have_text(message)
  end

  def resource_visibility(id)
    within("tr#resource_#{id}") do
      find('input[data-resource-visibility]')[:title]
    end
  end

  def cancel_form
    within('form') { click_link('Cancel') }
  end

  def save_form
    within('form') { click_button('Save') }
  end

  def click_edit_resource
    click_link('Edit resource')
  end

  def script_injected_text
    '<script> window.close(); </script>'
  end

  def select_from_units(option_name)
    # Resources homepage and edit page have
    # different selectors for the unit dropdown
    # and it is unsure which page calls it
    unit_options =  '.test-browse-by-unit'
    begin
    find(unit_options)
  rescue Capybara::ElementNotFound
    unit_options = '.test-unit-options'
  end
  within(unit_options) do
    find('option', text: option_name).click
    end
  end

  def select_from_resource_components(option_name)
    within('.test-resource-resource-component-id') do
      find('option', text: option_name).click
    end
  end

  def virus_file
    virus_body = 'X5O!P%@AP[4\PZX54(P^)7CC)7}$' + 'EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
    filename = 'virus.txt'
    file_path = Rails.root.join('tmp', filename)
    File.open(file_path, 'w') { |f| f.write virus_body }
    file_path
  end

  context 'As a student,' do
    let(:student) { create(:student) }
    let(:instructor) { create(:instructor) }
    let(:other_instructor) { create(:instructor) }
    let(:section) { create(:section_with_course, instructor: instructor) }
    let(:unauthorized_program) { create(:program) }
    let(:program) { section.course.program }
    let(:resource_component) { create(:resource_component) }
    let(:forbidden_resource) do
      create(
        :resource,
        program: unauthorized_program,
        vhl_student_resource: true,
        resource_component_id: resource_component.id
      )
    end
    let(:protected_resource) do
      create(
        :uploaded_resource,
        program: program,
        protected: true,
        owner_id: instructor.id,
        resource_component_id: resource_component.id
      )
    end
    let(:non_student_resource) do
      create(
        :uploaded_resource,
        program: program,
        vhl_student_resource: false,
        protected: false,
        owner_id: instructor.id,
        resource_component_id: resource_component.id
      )
    end
    let(:other_instructor_resource) do
      create(
        :uploaded_resource,
        program: program,
        vhl_student_resource: true,
        protected: false,
        owner_id: other_instructor.id,
        resource_component_id: resource_component.id
      )
    end

    before do
      initialize_program_access_client_calls_for_user_and_program(student, program)
      give_user_access_to_program(student, program)
      create(:enrollment, user: student, section: section)
      log_in_as(student)
    end

    scenario 'I am only allowed to download certain resources' do
      purpose 'I cannot download a resource that does not belong to my program' do
        step 'Visit download_resource_path(unauthorized_program, forbidden_resource)' do
          skip "SEE: https://vistahl.atlassian.net/browse/MAE-54225"
          visit download_resource_path(unauthorized_program, forbidden_resource)
        end
        step 'I get redirected to ua' do
          expect_redirection_to_ua(unauthorized_program)
        end
      end

      purpose 'I cannot download a protected resource' do
        step 'visit download_resource_path(program, protected_resource)' do
          visit download_resource_path(program, protected_resource)
        end
        step 'I see a 404 error' do
          expect_404
        end
      end

      purpose 'I cannot download a resource that is not visible to students' do
        step 'visit download_resource_path(program, non_student_resource)' do
          visit download_resource_path(program, non_student_resource)
        end
        step 'I see a 404 error' do
          expect_404
        end
      end

      purpose 'I cannot download a resource that is visible to students but my instructor has hidden it' do
        hidden_resource = create(:resource, program: program, vhl_student_resource: true)
        create(
          :hidden_instructor_resource_setting,
          instructor: instructor,
          resource: hidden_resource
        )
        step 'visit download_resource_path(program, hidden_resource)' do
          visit download_resource_path(program, hidden_resource)
        end
        step 'I see a 404 error' do
          expect_404
        end
      end
    end
  end

  context 'As an instructor,' do
    let(:instructor) { create(:instructor) }
    let(:other_instructor) { create(:instructor) }
    let(:program) { create(:program_with_lessons_and_resource_units) }
    let(:unauthorized_program) { create(:program) }
    let(:lessons) { program.lessons }
    let(:resource_component_1) do
      create(
        :resource_component,
        name: 'resource_component_1',
        program: program
      )
    end
    let(:resource_component_2) do
      create(
        :resource_component,
        name: 'resource_component_2',
        program: program
      )
    end
    let(:resource_component_3) do
      create(
        :resource_component,
        name: 'resource_component_3',
        program: program
      )
    end

    let!(:resource_1) do
      create(
        :resource,
        title: 'resource_1',
        program: program,
        resource_component_id: resource_component_1.id,
        protected: false,
        vhl_student_resource: true,
        lesson_id: lessons.first.id,
        start_unit_id: program.units.first.id
      )
    end
    let!(:resource_2) do
      create(
        :resource,
        title: 'resource_2',
        program: program,
        resource_component_id: resource_component_2.id,
        protected: false,
        vhl_student_resource: true,
        lesson_id: lessons.second.id,
        start_unit_id: program.units.second.id
      )
    end
    let!(:resource_3) do
      create(
        :resource,
        title: 'resource_3',
        program: program,
        resource_component_id: resource_component_3.id,
        protected: false,
        vhl_student_resource: true,
        lesson_id: lessons.second.id,
        start_unit_id: program.units.second.id
      )
    end
    let!(:visible_resource) do
      create(
        :resource,
        title: 'visible_resource',
        program: program,
        resource_component_id: resource_component_3.id,
        protected: false,
        vhl_student_resource: true,
        lesson_id: lessons.second.id,
        start_unit_id: program.units.second.id
      )
    end
    let!(:hidden_resource) do
      create(
        :resource,
        title: 'hidden_resource',
        program: program,
        resource_component_id: resource_component_3.id,
        protected: false,
        vhl_student_resource: false,
        lesson_id: lessons.second.id,
        start_unit_id: program.units.second.id
      )
    end
    let!(:never_visible_resource) do
      create(
        :resource,
        title: 'never_visible_resource',
        program: program,
        resource_component_id: resource_component_3.id,
        protected: true,
        lesson_id: lessons.second.id,
        start_unit_id: program.units.second.id
      )
    end
    let(:forbidden_resource) do
      create(
        :resource,
        program: unauthorized_program,
        resource_component_id: resource_component_1.id
      )
    end
    let(:other_instructor_resource) do
      create(
        :resource,
        program: program,
        owner_id: other_instructor.id,
        resource_component_id: resource_component_1.id
      )
    end

    let(:title_1) { 'title_1' }
    let(:title_2) { 'title_2' }
    let(:title_3) { 'title_3' }
    let(:title_4) { 'title_4' }

    def select_resource(id)
      # Selenium complains about the element
      # not clickable at point (x, y)
      page.execute_script("$('#resource_#{id}_checkbox')[0].click()")
    end

    before do
      initialize_program_access_client_calls_for_instructor(instructor, program)
      give_user_access_to_program(instructor, program)
      log_in_as(instructor)
      clear_downloads
    end

    after do
      clear_downloads
    end

    scenario 'I can create/edit/download/delete resources', downloads: true, retry: 2 do
      purpose 'I cannot download a resource that does not belong to my program' do
        step 'visit download_resource_path(unauthorized_program, forbidden_resource)' do
          skip "SEE: https://vistahl.atlassian.net/browse/MAE-54225"
          visit download_resource_path(unauthorized_program, forbidden_resource)
        end
        step 'I get redirected to ua' do
          expect_redirection_to_ua(unauthorized_program)
        end
      end

      purpose 'Without a course I can see a resources home page' do
        step 'Go to the resources home page' do
          visit instructor_program_resources_path(program)
        end
        step 'Check if the page structure is complete' do
          expect(page).to have_selector('h1',  text: 'Resources')
          expect(page).to have_text('All Components')
          expect(page).to have_text(resource_component_1.name)
          expect(page).to have_link(resource_1.title)
          expect(page).to have_link('Add Resource')
          expect(page).to have_link('Download')
        end
        step 'Create course records for this instructor in the database' do
          create(:course, program: program, owner: instructor)
        end
      end

      purpose 'I cannot edit a resource component' do
        step 'The page does not contain an "Edit components" button' do
          expect(page).to have_no_text('Edit components')
        end
      end

      purpose 'I can browse resources by unit' do
        step 'Go to the resources page' do
          visit instructor_program_resources_path(program)
        end
        step 'Select a different unit from the unit dropdown' do
          select_from_units(lessons.second.name)
        end
        step 'The resource list is updated' do
          expect(page).to have_no_link(resource_1.title)
          expect(page).to have_link(resource_2.title)
        end
      end

      purpose 'I can refine my browsing by component' do
        step 'I select a component' do
          within('#browse_by_component') do
            click_link(text: resource_component_3.name)
          end
        end
        step 'The resource list is updated' do
          expect(page).to have_no_link(resource_2.title)
          expect(page).to have_link(resource_3.title)
        end
      end

      purpose 'When creating a resource I can cancel the procedure' do
        step 'Click on the link to create a new resource' do
          click_link('Add Resource')
        end
        step 'Add a title' do
          fill_in 'Title', with: title_1
        end
        step 'Click on the cancel button' do
          cancel_form
        end
        step 'I do not see that resource' do
          expect(page).to have_no_link(title_1)
        end
      end

      purpose 'When creating a resource a title and a file are required' do
        step 'Click on the link to create a new resource' do
          click_link('Add Resource')
        end
        step 'Click on the save button' do
          save_form
        end
        step 'I see an error message saying that a title is required' do
          expect_error('Title is required')
        end
        step 'I see an error message saying that a file is required' do
          expect_error('File is required')
        end
        step 'Add a title' do
          fill_in 'Title', with: title_2
        end
        step 'Click on the save button' do
          save_form
        end
        step 'I see an error message saying that a file is required' do
          expect_error('File is required')
        end
        step 'Remove the title' do
          fill_in 'Title', with: ''
        end
        step 'Add a file' do
          attach_file('uploaded_file', Rails.root.join('public', 'images', 'VHLlogo.jpg'))
        end
        step 'Click on the save button' do
          save_form
        end
        step 'I see an error message saying that a title is required' do
          expect_error('Title is required')
        end
        step 'Add a title again' do
          fill_in 'Title', with: title_2
        end
        step 'Add a file' do
          attach_file('uploaded_file', Rails.root.join('public', 'images', 'VHLlogo.jpg'))
        end
        step 'Select first unit' do
          select_from_units(lessons.first.name)
        end
        step 'Select first component' do
          select_from_resource_components(resource_component_1.name)
        end
        step 'Click on save button, I see a success message' do
          save_form
        end
        step 'I see a success message' do
          expect_flash('notice', 'New resource created')
        end
        step 'The page displays the resource' do
          expect(page).to have_link(title_2)
        end
      end

      purpose 'When I change some fields they are saved' do
        step 'Click on the edit button of the resource' do
          click_link('Edit resource')
        end
        step 'Set a new title' do
          fill_in 'Title', with: title_3
        end
        step 'Set a description containing a script injection' do
          fill_in 'Description', with: script_injected_text
        end
        step 'Select a new file' do
          attach_file('uploaded_file', Rails.root.join('public', 'images', 'VHLlogo.jpg'))
        end
        step 'Select a different lesson' do
          select_from_units(lessons.second.name)
        end
        step 'Select a different component' do
          select_from_resource_components(resource_component_2.name)
        end
        step 'Mark the resource as not visible to students' do
          find('label[for=resource_student_visibility_false]').click
        end
        step 'Click on the save button' do
          save_form
        end
        step 'I see a success message' do
          expect_flash('notice', 'Your changes to the resource were saved')
        end
        step 'The page displays the resource correctly' do
          edited_resource = Resource.find_by_title(title_3)
          expect(page).to have_no_link(title_2)
          expect(page).to have_no_link(title_3)
          select_from_units(lessons.second.name)
          expect(page).to have_link(title_3)
          expect(resource_visibility(edited_resource.id)).to have_text('Hidden from student')
        end
      end

      purpose 'When editing a resource the form is filled with saved information' do
        resource = Resource.find_by_title(title_3)
        step 'Click on the edit button of the resource' do
          click_link('Edit resource')
        end
        step 'The title is set' do
          expect(find_field('resource_title').value).to be_eql(resource.title)
        end
        step 'The description text has been sanitized' do
          within('#resource_description') { expect(page).to have_no_selector('script') }
        end
        step 'File information are displayed' do
          within('.test-uploaded_file_information') do
            expect(find('.u-txt-bold')).to have_text(resource.file_name)
          end
        end
        step 'The lesson is selected' do
          expect(find('#unit_options').value).to include("start_unit_id=#{resource.start_unit_id}")
        end
        step 'The component is selected' do
          expect(find('#resource_resource_component_id').value.to_i).to eq(resource.resource_component_id)
        end
        step 'The "protected" checkbox is checked' do
          expect(find('#resource_student_visibility_true').value).to eq('true')
        end
      end

      purpose 'I cannot upload a virus-y file' do
        step 'Select a virus-y file' do
          attach_file('uploaded_file', virus_file)
          save_form
        end
        step 'I see an error message' do
          expect_flash(
            :error,
            "Your file could not be uploaded because it seems" \
            " to be infected with the virus 'Virus.Based.0N.Filename'"
          )
          cancel_form
        end
      end

      purpose 'When editing a resource I can cancel the procedure' do
        step 'Click on the edit button and set a new title' do
         click_edit_resource
         fill_in 'Title', with: title_4
        end
        step 'Click on the cancel button' do
          cancel_form
        end
        step 'The resource page displays the previously saved resource' do
          expect(page).to have_no_link(title_4)
          expect(page).to have_link(title_3)
        end
      end

      purpose 'I can download a resource' do
        download_link = page.find_link('Download')

        bucket = instance_double(Radner::S3Storage, fetch: 'fake_content')
        allow(Radner::S3Storage).to receive(:new).and_return(bucket)

        step 'The "download" button is disabled' do
          expect(download_link[:disabled]).to eq('disabled')
        end
        step 'Select a resource' do
          select_resource(resource_2.id)
        end
        step 'The "download" button is enabled' do
          expect(download_link[:disabled]).to be nil
        end
        enable_headless_downloads do
          step 'Click the "download" button' do
            download_link.click
          end
          step 'A file named "downloaded_resources.zip" is downloaded' do
            wait_for_download
            expect(last_downloaded_file).to include('downloaded_resources.zip')
          end
        end
        step 'unselect the last selection' do
          # Workaround to unselect the resource
          select_resource(resource_2.id)
          select_resource(resource_2.id)
        end
      end

      purpose 'I can change the resource visibility of multiple resources' do
        visibility_class_disabled = ".js-visibility-action[disabled='disabled']"
        visibility_container = find('.resource_tools')
        step 'The "Change visibility" button is disabled' do
          within(visibility_container) do
            expect(page).to have_selector(visibility_class_disabled)
          end
        end
        step 'Select a visible resource "v", a hidden resource "h" and a never visible resource "n"' do
          [visible_resource, hidden_resource, never_visible_resource].each do |resource|
            select_resource(resource.id)
          end
        end
        step 'The "Change visibility" button is enabled' do
          within(visibility_container) do
            expect(page).to have_no_selector(visibility_class_disabled)
          end
        end
        step 'Change visibility to "hide from students"' do
          within('.resource_tools') do
            find('.test-hide-from-student', text: 'hide').click
          end
          wait_for_ajax
        end
        step 'resource "v" and "h" are marked as "hidden from students"' do
          [visible_resource, hidden_resource].each do |resource|
            resource_setting = visible_resource.instructor_resource_settings.first
            expect(resource_setting.hidden?).to be_truthy
            expect(resource_visibility(resource.id)).to have_text('Hidden from students')
          end
        end
        step 'resource "n" is marked as "never visible to students"' do
          resource_setting = never_visible_resource.instructor_resource_settings
          expect(resource_setting).to be_empty
          expect(resource_visibility(never_visible_resource.id)).to have_text('Never visible to students')
        end
        step 'Change visibility to "visible to students"' do
          [visible_resource, hidden_resource, never_visible_resource].each do |resource|
            select_resource(resource.id)
          end
          within('.resource_tools') do
            find('.test-show-to-student', text: 'show').click
          end
          wait_for_ajax
        end
        step 'resource "v" and "h" are marked as "visible to students"' do
          [visible_resource, hidden_resource].each do |resource|
            resource_setting = visible_resource.instructor_resource_settings.first
            expect(resource_setting.shown?).to be_truthy
            expect(resource_visibility(resource.id)).to have_text('Visible to students')
          end
        end
        step 'resource "n" is marked as "never visible to students"' do
          expect(resource_visibility(never_visible_resource.id)).to have_text('Never visible to students')
        end
      end

      purpose 'When deleting a resource' do
        step 'Click on the delete button of the resource' do
          find('.js-delete-btn').click
        end
        step 'A messagebox with text "DELETE THIS RESOURCE" is displayed' do
          expect(page).to have_text('DELETE THIS RESOURCE')
        end
        step 'Click on the cancel button' do
          find('.test-cancel-btn').click
        end
        step 'The resource page displays the resource' do
          expect(page).to have_link(title_3)
        end
        step 'Click on the delete button of the resource' do
          find('.js-delete-btn').click
        end
        step 'A messagebox with text "DELETE THIS RESOURCE" is displayed' do
          expect(page).to have_text('DELETE THIS RESOURCE')
        end
        step 'Click on the "delete this resource" button' do
          click_link('Delete this resource')
        end
        step 'I see a success message' do
          expect_flash('notice', "Resource '#{title_3}' has been deleted")
        end
        step 'The resource page do not display the deleted resource' do
          expect(page).to have_no_link(title_3)
        end
      end
    end
  end

  # There is no assistant instructor tests, since it would be based on
  # the instructor tests that are currently being skipped.

  context 'As a resource editor,' do
    let(:resource_editor) { create(:instructor) }
    let(:program) { create(:program_with_lessons_and_resource_units) }
    let(:lessons) { program.lessons }
    let!(:resource_component_1) do
      create(
        :resource_component,
        name: 'resource_component_1',
        program: program
      )
    end
    let!(:resource_component_2) do
      create(
        :resource_component,
        name: 'resource_component_2',
        program: program
      )
    end
    let!(:resource_1) do
      create(
        :resource,
        title: 'resource_1',
        program: program,
        resource_component_id: resource_component_1.id,
        protected: false,
        vhl_student_resource: true,
        lesson_id: lessons.first.id,
        start_unit_id: program.units.first.id
      )
    end
    let(:resource_2) { build_stubbed(:resource, title: 'resource_2') }
    let(:resource_2_new_title) { 'resource_2_edited' }

    before do
      initialize_program_access_client_calls_for_instructor(resource_editor, program)
      give_user_access_to_program(resource_editor, program)
      resource_editor.roles << Role.new(name: Role::RESOURCE_EDITOR)
    end

    scenario 'I can create/edit/delete resources' do
      purpose 'I log in as a resource editor' do
        log_in_as(resource_editor)
      end

      purpose 'I see the resource home page' do
        step 'Go to resource home page' do
          visit instructor_program_resources_path(program)
        end
        step 'Check if the page structure is complete' do
          expect(page).to have_selector('h1',  text: 'Resources')
          expect(page).to have_text('All Components')
          expect(page).to have_text(resource_component_1.name)
          expect(page).to have_link(resource_1.title)
          expect(page).to have_link('Edit components')
          expect(page).to have_link('Add Resource')
          expect(page).to have_link('Download')
        end
      end

      purpose 'When creating a resource I can cancel the procedure' do
        step 'Click on the link to create a new resource' do
          click_link('Add Resource')
        end
        step 'Add a title' do
          fill_in 'Title', with: 'new_resource'
        end
        step 'Click on the cancel button' do
          cancel_form
        end
        step 'I do not see that resource' do
          expect(page).to have_no_link('new_resource')
        end
      end

      purpose 'When creating a resource a title and a file are required' do
        step 'Click on the link to create a new resource' do
          click_link('Add Resource')
        end
        step 'Click on the save button' do
          save_form
        end
        step 'I see an error message saying that a title is required' do
          expect_error('Title is required')
        end
        step 'I see an error message saying that a file is required' do
          expect_error('File is required')
        end
        step 'Add a title' do
          fill_in 'Title', with: resource_2.title
        end
        step 'Click on the save button' do
          save_form
        end
        step 'I see an error message saying that a file is required' do
          expect_error('File is required')
        end
        step 'Remove the title' do
          fill_in 'Title', with: ''
        end
        step 'Add a file' do
          attach_file('uploaded_file', Rails.root.join('public', 'images', 'VHLlogo.jpg'))
        end
        step 'Click on the save button' do
          save_form
        end
        step 'I see an error message saying that a title is required' do
          expect_error('Title is required')
        end
        step 'Add a title' do
          fill_in 'Title', with: resource_2.title
        end
        step 'Add a file' do
          attach_file('uploaded_file', Rails.root.join('public', 'images', 'VHLlogo.jpg'))
        end
        step 'Select first unit' do
          select_from_units(lessons.first.name)
        end
        step 'Select first component' do
          select_from_resource_components(resource_component_1.name)
        end
        step 'Click on the save button' do
          save_form
        end
        step 'I see a success message' do
          expect_flash('notice', 'New resource created')
        end
        step 'The page displays the resource' do
          expect(page).to have_link(resource_2.title)
        end
      end

      purpose 'When I change some fields they are saved' do
        resource_to_edit = Resource.find_by_title(resource_2.title)
        step 'Click on the edit button of the resource' do
          within("tr#resource_#{resource_to_edit.id}") { click_edit_resource }
        end
        step 'Set a new title' do
          within('form') { fill_in 'Title', with: resource_2_new_title }
        end
        step 'Set an harmfull description text' do
          within('form') { fill_in 'Description', with: script_injected_text }
        end
        step 'Select a new file' do
          attach_file('uploaded_file', Rails.root.join('public', 'images', 'VHLlogo.jpg'))
        end
        step 'Select a different lesson' do
          select_from_units(lessons.second.name)
        end
        step 'Select a different component' do
          select_from_resource_components(resource_component_2.name)
        end
        step 'Mark the resorce as protected' do
          vhl_check("Protected", allow_label_click: true)
        end
        step 'Mark the resource as not visible to students' do
          find('label[for=resource_student_visibility_false]').click
        end
        step 'Click on the save button' do
          save_form
        end
        step 'I see a success message' do
          expect_flash('notice', 'Your changes to the resource were saved')
        end
        step 'The page displays the resource correctly' do
          expect(page).to have_no_link(resource_2.title)
          select_from_units(lessons.second.name)
          expect(page).to have_link(resource_2_new_title)
          expect(resource_visibility(resource_to_edit.id)).to have_text('Never visible to students')
        end
        step 'The resource is never visible to students' do
          expect(resource_to_edit.reload).to be_protected
        end
      end

      purpose 'When editing a resource the form is filled with saved information' do
        resource_to_edit = Resource.find_by_title(resource_2_new_title)
        step 'Click on the edit button of the resource' do
          within("tr#resource_#{resource_to_edit.id}") { click_edit_resource }
        end
        step 'The title is set' do
          expect(find_field('resource_title').value.present?).to be_truthy
        end
        step 'The description text has been sanitized' do
          within('#resource_description') { expect(page).to have_no_selector('script') }
        end
        step 'File information are displayed' do
          within('.test-uploaded_file_information') do
            expect(find('.u-txt-bold')).to have_text(resource_to_edit.file_name)
          end
        end
        step 'The lesson is selected' do
          expect(find('#unit_options').value).to include("start_unit_id=#{resource_to_edit.start_unit_id}")
        end
        step 'The component is selected' do
          expect(find('#resource_resource_component_id').value.to_i).to eq(resource_to_edit.resource_component_id)
        end
        step 'The "protected" checkbox is checked' do
          expect(find('#resource_protected').checked?).to be_truthy
        end
        step 'The "visible to Students" radio button is selected' do
          expect(find('#resource_student_visibility_true').value).to eq('true')
        end
      end

      purpose 'I cannot upload a virus-y file' do
        step 'Select a virus-y file' do
          attach_file('uploaded_file', virus_file)
          save_form
        end
        step 'I see an error message' do
          expect_flash(
            :error,
            "Your file could not be uploaded because it seems" \
            " to be infected with the virus 'Virus.Based.0N.Filename'"
          )
          cancel_form
        end
      end

      purpose 'When editing a resource I can cancel the procedure' do
        resource_to_edit = Resource.find_by_title(resource_2_new_title)
        step 'Click on the edit button of the resource' do
          within("tr#resource_#{resource_to_edit.id}") { click_edit_resource }
        end
        step 'Set a new title' do
          fill_in 'Title', with: 'edit_resource_to_cancel'
        end
        step 'Click on the cancel button' do
          cancel_form
        end
        step 'The resource page displays the previously saved resource' do
          expect(page).to have_no_link('edit_resource_to_cancel')
          expect(page).to have_link(resource_to_edit.title)
        end
      end

      purpose 'When deleting a resource' do
        resource_to_delete = Resource.find_by_title(resource_2_new_title)
        step 'Click on the delete button of the resource' do
          within("tr#resource_#{resource_to_delete.id}") do
            find('.js-delete-btn').click
          end
        end
        step 'A messagebox with text "DELETE THIS RESOURCE" is displayed' do
          expect(page).to have_text('DELETE THIS RESOURCE')
        end
        step 'Click on the cancel button' do
          find('.test-cancel-btn').click
        end
        step 'The resource page displays the resource' do
          expect(page).to have_link(resource_to_delete.title)
        end
        step 'Click on the delete button of the resource' do
          within("tr#resource_#{resource_to_delete.id}") do
            find('.js-delete-btn').click
          end
        end
        step 'A messagebox with text "DELETE THIS RESOURCE" is displayed' do
          expect(page).to have_text('DELETE THIS RESOURCE')
        end
        step 'Click on the "delete this resource" button' do
          click_link('Delete this resource')
        end
        step 'I see a success message' do
          expect_flash('notice', "Resource '#{resource_to_delete.title}' has been deleted")
        end
        step 'The resource page do not display the deleted resource' do
          expect(page).to have_no_link(resource_to_delete.title)
        end
      end

      purpose 'I can create a resource component with an empty title' do
        step 'Click on the "Edit components" button in the resource page' do
          # Not clickable for selenium since flash message
          # from previous step appears on top of the button
          page.execute_script("$('a#new_resource_component_link')[0].click()")
        end
        step 'Click on "Add new component"' do
          click_on('Add new component')
        end
        step 'Click on the "Submit" button' do
          click_on('Submit')
        end
        step 'I see the message "Your component was created successfully."' do
          expect_flash('notice', 'Your component was created successfully')
        end
        step 'The Resource component page displays the resource componmemt correctly' do
          expect(page).to have_selector(".test-component-#{resource_component_1.id}",
                                        text: resource_component_1.name)
          expect(page).to have_selector(".test-component-#{resource_component_2.id}",
                                        text: resource_component_2.name)
          expect(page).to have_link('edit this component')
          expect(page).to have_link('delete this component')
        end
      end

      purpose 'I can edit a resource component' do
        step 'Click on "edit this component" link of the resource component' do
          within(".test-component-#{resource_component_1.id}") do
            find('#edit_resource_component_link').click
          end
        end
        fill_in 'Name', with: 'resource_component_3'
        click_on('Submit')
        step 'I see the message "Your changes to the resource component were saved."' do
          expect_flash('notice', 'Your changes to the resource component were saved')
        end
        resource_component_1.reload
        step 'The Resource component page displays the resource componemt correctly' do
          expect(page).to have_no_text('resource_component_1')
          expect(page).to have_selector(".test-component-#{resource_component_1.id}",
                                        text: 'resource_component_3')
          expect(page).to have_text(resource_component_2.name)
        end
      end

      purpose 'When editing a resource component the text field is filled with the saved title' do
        step 'Click on "edit this component" link of the resource component' do
          within(".test-component-#{resource_component_2.id}") do
            find('#edit_resource_component_link').click
          end
        end
        step 'The title is set' do
          expect(find_field('Name').value).to eq(resource_component_2.name)
        end
      end

      purpose 'When editing a resource component I can cancel the procedure' do
        click_on('Cancel')
        step 'The Resource component page displays the resource componemt correctly' do
          expect(page).to have_text(resource_component_2.name)
          expect(page).to have_text('resource_component_3')
          expect(page).to have_link('edit this component')
          expect(page).to have_link('delete this component')
        end
      end

      purpose 'When deleting a resource component from the resource components page' do
        within(".test-component-#{resource_component_2.id}") do
          find('#delete_resource_component_link').click
        end
        step 'An alert with the text "Are you sure?" is displayed'
        step 'Confirm' do
          accept_alert('Are you sure?')
        end
        step 'The resource component does not appears on the resource components page' do
          expect_flash('notice', 'Your component was deleted')
          expect(page).to have_no_text('resource_component_2')
          expect(page).to have_text(resource_component_1.name)
        end
      end

      purpose 'When deleting a resource component from the resource component edit page' do
        click_on('Add new component')
        fill_in 'Name', with: 'resource_component_4'
        click_on('Submit')
        step 'I see the message "Your component was created successfully."' do
          expect_flash('notice', 'Your component was created successfully')
        end
        step 'Click on "edit this component" link of the resource component' do
          all('#edit_resource_component_link').last.click
        end
        step 'Click on the "Delete?" link' do
          click_on('Delete?')
        end
        step 'An alert with the text "Are you sure?" is displayed'
        step 'Confirm' do
          accept_alert('Are you sure?')
        end
        step 'The resource component does not appears on the resource components page' do
          expect_flash('notice', 'Your component was deleted')
          expect(page).to have_no_text('resource_component_4')
          expect(page).to have_text(resource_component_1.name)
        end
      end
    end
  end
end

