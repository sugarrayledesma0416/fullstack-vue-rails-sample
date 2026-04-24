require 'rails_helper'

RSpec.describe 'Bulk Irs Upload', :js do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include_context 'when files were already uploaded to S3'
  include_context 'with a bulk csv file'

  let(:user) { create(:resource_editor_user) }
  let(:program) { create(:program_with_lessons) }
  let(:creator) { instance_double(BulkResourcesUploader::BulkResourcesCreator) }
  let(:tracker) { create(:bulk_resources_creation_tracker, program_id: program.id) }

  def wait_for_files_to_be_cleared(selector, timeout: 5)
    Timeout.timeout(timeout) do
      loop do
        files_count = page.evaluate_script("document.querySelector('#{selector}').files.length")
        return files_count if files_count == 0

        sleep 0.1
      end
    end
  rescue Timeout::Error
    page.evaluate_script("document.querySelector('#{selector}').files.length")
  end

  def mock_files_status(zip_exist, csv_exist, zip_last_modified, csv_last_modified)
    allow(creator).to receive_messages(
      zip_exist_in_s3?: zip_exist,
      csv_exist_in_s3?: csv_exist,
      files_status: {
        zip: zip_exist,
        zip_last_modified:,
        csv: csv_exist,
        csv_last_modified:
      }
    )
  end

  def mock_validation_process(errors_number, warnings_number, errors_breakdown)
    allow(creator).to receive(:validate_bulk_process) do
      # This is needed because sl-details component requires a delay to complete the close and open
      # transition otherwise the internal components are not interactable
      sleep(2)
      {
        errors_number:,
        warnings_number:,
        errors_breakdown:
      }
    end
  end

  before do
    log_in_as(user)
    allow(BulkResourcesController).to receive(:generate_presigned_url).and_return(
      {
        url: 'https://test-bucket.s3.amazonaws.com/',
        fields: { 'key' => 'test-key', 'acl' => 'private' }
      }.to_json
    )
    allow(BulkResourcesUploader::BulkResourcesCreator).to receive(:new).and_return(creator)
    mock_files_status(false, false, nil, nil)
    visit upload_bulk_resources_uploader_path(program.id)
  end

  scenario 'As a resource editor, I can see the bulk resources upload page' do
    purpose 'The user can see the bulk resources uploader component and its initial state' do
      step 'The user can see the bulk resources uploader component' do
        expect(page).to have_css('.irs-steps-accordion')
      end
      step 'The user can see the uploads details section' do
        expect(page).to have_css('.uploads-sl-details')
      end

      step 'The uploads details section is open' do
        uploads_details = find('sl-details.uploads-sl-details')
        expect(uploads_details[:open]).to eq('true')
      end

      step 'The uploads details section shows an error state' do
        expect(page).to have_css('.uploads-sl-details.border-color-error')
      end

      step 'The user can see the validation details section is closed' do
        validation_details = find('sl-details.validation-sl-details')
        expect(validation_details[:open]).to eq('false')
      end

      step 'The user can see the creation details section is disabled' do
        creation_details = find('sl-details.creation-sl-details')
        expect(creation_details[:disabled]).to eq('true')
      end

      step 'I see the delete resources button' do
        expect(page).to have_css('.delete-resources-button')
      end

      step 'The user can see the delete resources button is disabled' do
        delete_resources_button = find('.delete-resources-button')
        expect(delete_resources_button['disabled']).to be_truthy
      end
    end
  end

  scenario 'As a resource editor, I can verify file format validations' do
    purpose 'The user cannot upload a CSV file in the ZIP input' do
      step 'The user can see the bulk resources uploader component' do
        expect(page).to have_css('.irs-steps-accordion')
      end

      step 'The user can see the uploads details section' do
        expect(page).to have_css('.uploads-sl-details')
      end
      step 'The zip input accepts only ZIP files' do
        zip_input = find('input.test-bulk-upload-zip-input', visible: false)
        expect(zip_input['accept']).to eq('.zip')
        expect(zip_input['type']).to eq('file')
      end

      step 'The user tries to upload a CSV file in the ZIP input' do
        find('input.test-bulk-upload-zip-input', visible: false).set(csv_file_path)
      end

      step 'The user can see that the file was not uploaded' do
        expect(wait_for_files_to_be_cleared('.test-bulk-upload-zip-input')).to eq(0)
      end
    end

    purpose 'The user cannot upload a ZIP file in the CSV input' do
      step 'the csv input accepts only CSV files' do
        csv_input = find('input.test-bulk-upload-csv-input', visible: false)
        expect(csv_input['accept']).to eq('.csv')
        expect(csv_input['type']).to eq('file')
      end

      step 'The user tries to upload a ZIP file in the CSV input' do
        find('input.test-bulk-upload-csv-input', visible: false).set(no_errors_zip_path)
      end

      step 'The user can see that the file was not uploaded' do
        expect(wait_for_files_to_be_cleared('.test-bulk-upload-csv-input')).to eq(0)
      end
    end
  end

  scenario 'As a resource editor, I can successfully upload files' do
    purpose 'The upload disclosure is open' do
      step 'The user can see the bulk resources uploader component - initial state' do
        expect(page).to have_css('.irs-steps-accordion')
        uploads_details = find('sl-details.uploads-sl-details')
        expect(uploads_details[:open]).to eq('true')
      end

      purpose 'The user can upload a ZIP and CSV file' do
        step 'The user uploads the ZIP file' do
          mock_files_status(false, false, Time.current, nil)
          find('input.test-bulk-upload-zip-input', visible: false).set(no_errors_zip_path)
        end

        step 'The user can see the zip file is being uploaded' do
          within('.uploads-sl-details') do
            expect(page).to have_css('.test-bulk-upload-zip-spinner', wait: 5)
          end
        end

        step 'The user uploads the CSV file' do
          mock_files_status(true, false, Time.current, Time.current)
          mock_validation_process(0, 0, {})
          stub_request(:post, "#{upload_bulk_resources_uploader_path(program.id)}/upload_csv")
            .to_return(status: 200, body: { file_uploaded: true }.to_json)
          find('input.test-bulk-upload-csv-input', visible: false).set(csv_file_path)
        end

        step 'The user can see the csv file is being uploaded' do
          within('.uploads-sl-details') do
            expect(page).to have_css('.test-bulk-upload-csv-spinner', wait: 5)
          end
        end
      end
    end

    purpose 'The user can see the files status in the table' do
      step 'The user open the uploads details section' do
        find('.uploads-sl-details').click
      end

      step 'I see the files status table with uploaded files' do
        within('.uploads-sl-details .sl-details__content__l-grid') do
          within('.test-bulk-upload-status-table') do
            expect(page).to have_css('th', text: 'ZIP')
            expect(page).to have_css('th', text: 'CSV')
            expect(page).to have_css('td', text: 'Uploaded')
            expect(page).to have_css('td', text: 'Uploaded')
          end
        end
      end
    end
  end

  scenario 'As a resource editor, I can see validation errors' do
    purpose 'The validation process starts automatically after uploads' do
      step 'The user visits the bulk resources uploader page and files are already uploaded' do
        expect(page).to have_css('.irs-steps-accordion')
        mock_files_status(true, true, Time.current, Time.current)
        errors_hash = {
          file_not_found: { size: 2, message: 'File not found' },
          invalid_characters: { size: 1, message: 'Invalid characters' },
          unit_out_of_range: { size: 2, message: 'Unit out of range' }
        }
        mock_validation_process(5, 2, errors_hash)
        visit upload_bulk_resources_uploader_path(program.id)
      end

      step 'The user can see the validation table is visible' do
        expect(page).to have_css('.test-bulk-validation-status-table-summary', wait: 5)
      end

      step 'The user can see the validation section shows error state' do
        expect(page).to have_css('.validation-sl-details.border-color-error')
        expect(page).to have_no_css('.validation-sl-details.border-color-success')
      end
    end

    purpose 'The user can see the validation errors' do
      step 'The user can see the validation section shows error state' do
        expect(page).to have_css('.validation-sl-details.border-color-error')
        expect(page).to have_no_css('.validation-sl-details.border-color-success')
      end

      step 'The user can see the download report button is enabled' do
        validation_details = find('.validation-sl-details')
        expect(validation_details).to have_button('Download report', disabled: false)
      end
    end

    purpose 'The user can see the error details in the table' do
      step 'The user can see the file not found errors' do
        within('.validation-sl-details .l-col-7 .test-bulk-validation-status-table') do
          expect(page).to have_css('tr', text: 'file_not_found')
          expect(page).to have_css('tr', text: '2')
          expect(page).to have_css('tr', text: 'File not found')
        end
      end

      step 'The user can see the invalid characters errors' do
        within('.validation-sl-details .l-col-7 .test-bulk-validation-status-table') do
          expect(page).to have_css('tr', text: 'invalid_characters')
          expect(page).to have_css('tr', text: '1')
          expect(page).to have_css('tr', text: 'Invalid characters')
        end
      end

      step 'The user can see the unit out of range errors' do
        within('.validation-sl-details .l-col-7 .test-bulk-validation-status-table') do
          expect(page).to have_css('tr', text: 'unit_out_of_range')
          expect(page).to have_css('tr', text: '2')
          expect(page).to have_css('tr', text: 'Unit out of range')
        end
      end
    end

    purpose 'The validation disclosure stays open' do
      step 'The user can see the validation table is visible' do
        expect(page).to have_css('.test-bulk-validation-status-table-summary', wait: 5)
      end
    end
  end

  scenario 'As a resource editor, I can see validation warnings' do
    purpose 'The user can start the validation process' do
      step 'The user visits the bulk resources uploader page and files are already uploaded' do
        mock_files_status(true, true, Time.current, Time.current)
        mock_validation_process(0, 2, {})
        visit upload_bulk_resources_uploader_path(program.id)
      end

      step 'The user can see the validation table is visible' do
        expect(page).to have_css('.test-bulk-validation-status-table-summary', wait: 5)
      end

      step 'The user can see the validation section shows warning state' do
        expect(page).to have_css('.validation-sl-details.border-color-warning')
        expect(page).to have_no_css('.validation-sl-details.border-color-error')
        expect(page).to have_no_css('.validation-sl-details.border-color-success')
      end
    end
  end

  scenario 'As a resource editor, I can see successful validation' do
    purpose 'The user can start the validation process' do
      step 'The user visits the bulk resources uploader page and files are already uploaded' do
        mock_files_status(true, true, Time.current, Time.current)
        mock_validation_process(0, 0, {})
        visit upload_bulk_resources_uploader_path(program.id)
      end
    end

    purpose 'The user can see the validation success' do
      step 'I see the validation section shows success state' do
        expect(page).to have_css('.validation-sl-details.border-color-success')
        expect(page).to have_no_css('.validation-sl-details.border-color-error')
        expect(page).to have_no_css('.validation-sl-details.border-color-warning')
      end
    end

    purpose 'The validation disclosure closes automatically' do
      step 'The user can see the validation table is not visible' do
        expect(page)
          .to have_css('.test-bulk-validation-status-table-summary', visible: :hidden, wait: 5)
      end
    end
  end

  scenario 'As a resource editor, I can delete resources' do
    purpose 'The user can start the validation process' do
      step 'The user visits the bulk resources uploader page and files are already uploaded' do
        mock_files_status(true, true, Time.current, Time.current)
        mock_validation_process(0, 0, {})
        visit upload_bulk_resources_uploader_path(program.id)
      end

      step 'The user can see the validation table is visible' do
        expect(page).to have_css('.test-bulk-validation-status-table-summary', wait: 5)
      end

      step 'The user can see the validation section shows success state' do
        expect(page).to have_css('.validation-sl-details.border-color-success')
        expect(page).to have_no_css('.validation-sl-details.border-color-error')
        expect(page).to have_no_css('.validation-sl-details.border-color-warning')
      end
    end

    purpose 'The user can see the validation success' do
      step 'The user can see the validation section shows success state' do
        expect(page).to have_css('.validation-sl-details.border-color-success')
        expect(page).to have_no_css('.validation-sl-details.border-color-error')
        expect(page).to have_no_css('.validation-sl-details.border-color-warning')
      end
    end

    purpose 'I can enable the delete resources button' do
      step 'I see the validation section shows success state' do
        expect(page).to have_css('.validation-sl-details.border-color-success')
      end

      step 'I verify the delete resources button is enabled' do
        delete_resources_button = find('.delete-resources-button')
        expect(delete_resources_button[:disabled]).to eq('false')
      end
    end

    purpose 'I can click the delete resources button' do
      step 'I click the delete resources button' do
        delete_resources_button = find('.delete-resources-button')
        delete_resources_button.click
      end
    end

    purpose 'I can confirm the deletion in the modal' do
      step 'I see the confirmation dialog' do
        expect(page).to have_css('.test-delete-confirmation-modal')
      end

      step 'I see the confirmation message' do
        within('.test-delete-confirmation-modal') do
          expect(page)
            .to have_css('p', text: 'This action will permanently delete all ' \
                                    'the resources for this book. Are you sure?')
        end
      end
    end
  end

  scenario 'As a resource editor, I can create and track a bulk creation process' do
    purpose 'I can start the validation process' do
      step 'I can see the bulk resources uploader component' do
        expect(page).to have_css('.irs-steps-accordion')
        mock_files_status(true, true, Time.current, Time.current)
        mock_validation_process(0, 0, {})
        visit upload_bulk_resources_uploader_path(program.id)
      end

      step 'The user can see the validation table is visible' do
        expect(page).to have_css('.test-bulk-validation-status-table-summary', wait: 5)
      end
    end

    purpose 'The user can see the validation success' do
      step 'The user can see the validation section shows success state' do
        expect(page).to have_css('.validation-sl-details.border-color-success')
        expect(page).to have_no_css('.validation-sl-details.border-color-error')
        expect(page).to have_no_css('.validation-sl-details.border-color-warning')
      end
    end

    purpose 'I can see the creation disclosure' do
      step 'I see the creation section title' do
        expect(page).to have_css('h5', text: 'Creation:')
      end

      step 'I see the creation section description' do
        expect(page).to have_css('p', text: "Here you'll be able to start the " \
                                            'creation process.')
      end
    end

    purpose 'I can see the creation table initial state' do
      step 'I verify the creation table structure' do
        within('.creation-sl-details') do
          within('.test-bulk-creation-status-table') do
            expect(page).to have_css('tr', text: 'No creation in progress')
          end
        end
      end
    end

    purpose 'I can start the creation process' do
      allow(BulkResourcesCreationTracker).to receive(:find_by).and_return(tracker)
      step 'I click the start creation button' do
        stub_request(:post, "#{upload_bulk_resources_uploader_path(program.id)}/start_creation")
          .to_return(status: 200)
        start_creation_button = find('.test-bulk-creation-start-button')
        expect(start_creation_button[:disabled]).to eq('false')
        start_creation_button.click
      end
    end

    purpose 'I can track the creation process' do
      step 'The interface is blocked by an overlay while the creation process is in progress' do
        expect(page).to have_css('.test-bulk-upload-blur-screen', wait: 12)
      end

      step 'I see the creation dialog' do
        expect(page).to have_css('.test-bulk-creation-status-table')
      end

      step 'I see the loading text is displayed' do
        expect(page).to have_css('.test-bulk-creation-status-table-loading-text')
      end

      step 'I see the job_created step in the creation table' do
        tracker.job_created!
        expect(page).to have_css('tr', text: 'job_created', wait: 12)
      end

      step 'I see the unzipping_started step in the creation table' do
        tracker.start_unzipping!
        expect(page).to have_css('tr', text: 'unzipping_started', wait: 12)
      end

      step 'I see the unzipping_completed step in the creation table' do
        tracker.unzipping_completed!
        expect(page).to have_css('tr', text: 'unzipping_completed', wait: 12)
      end

      step 'I see the creation_started step in the creation table' do
        tracker.start_creating_resources!
        expect(page).to have_css('tr', text: 'creation_started', wait: 12)
      end

      step 'I see the creation_completed step in the creation table' do
        tracker.completed!
        expect(page).to have_css('tr', text: 'creation_completed', wait: 12)
      end

      step 'The blocking overlay disappears when the process completes' do
        expect(page).to have_no_css('.test-bulk-upload-blur-screen', wait: 12)
      end
    end
  end

  scenario 'As a resource editor, I can track an error in the creation process' do
    purpose 'I can start the validation process' do
      step 'I can see the bulk resources uploader component' do
        expect(page).to have_css('.irs-steps-accordion')
        mock_files_status(true, true, Time.current, Time.current)
        mock_validation_process(0, 0, {})
        visit upload_bulk_resources_uploader_path(program.id)
      end

      step 'The user can see the validation process has started' do
        expect(page).to have_css('.test-bulk-validation-status-table-summary', wait: 5)
      end
    end

    purpose 'The user can see the validation success' do
      step 'The user can see the validation section shows success state' do
        expect(page).to have_css('.validation-sl-details.border-color-success')
        expect(page).to have_no_css('.validation-sl-details.border-color-error')
        expect(page).to have_no_css('.validation-sl-details.border-color-warning')
      end
    end

    purpose 'I can see the creation disclosure' do
      step 'The user can see the creation section title' do
        expect(page).to have_css('h5', text: 'Creation:')
      end

      step 'The user can see the creation section description' do
        expect(page).to have_css('p', text: "Here you'll be able to start the " \
                                            'creation process.')
      end
    end

    purpose 'I can see the creation table initial state' do
      step 'The user can see the creation table structure' do
        within('.creation-sl-details') do
          within('.test-bulk-creation-status-table') do
            expect(page).to have_css('tr', text: 'No creation in progress')
          end
        end
      end
    end

    purpose 'I can start the creation process' do
      allow(BulkResourcesCreationTracker).to receive(:find_by).and_return(tracker)
      step 'The user can click the start creation button' do
        stub_request(:post, "#{upload_bulk_resources_uploader_path(program.id)}/start_creation")
          .to_return(status: 200)
        start_creation_button = find('.test-bulk-creation-start-button')
        expect(start_creation_button[:disabled]).to eq('false')
        start_creation_button.click
      end
    end

    purpose 'As a resource editor, I can track the creation process' do
      step 'The user can see the interface is blocked during the creation process' do
        expect(page).to have_css('.test-bulk-upload-blur-screen', wait: 12)
      end

      step 'The user can see the creation dialog' do
        expect(page).to have_css('.test-bulk-creation-status-table')
      end

      step 'The user can see the loading text is displayed' do
        expect(page).to have_css('.test-bulk-creation-status-table-loading-text')
      end

      step 'The user can see the job_created step in the creation table' do
        tracker.job_created!
        expect(page).to have_css('tr', text: 'job_created', wait: 12)
      end

      step 'The user can see the unzipping_started step in the creation table' do
        tracker.start_unzipping!
        expect(page).to have_css('tr', text: 'unzipping_started', wait: 12)
      end

      step 'The user can see the unzipping_completed step in the creation table' do
        tracker.unzipping_completed!
        expect(page).to have_css('tr', text: 'unzipping_completed', wait: 12)
      end

      step 'The user can see the creation_started step in the creation table' do
        tracker.start_creating_resources!
        expect(page).to have_css('tr', text: 'creation_started', wait: 12)
      end

      step 'The user can see the creation_failed step in the creation table' do
        tracker.fail!
        tracker.log('creation_failed', 'Error starting creation process', 0)
        expect(page).to have_css('tr', text: 'creation_failed', wait: 12)
        expect(page).to have_css('tr', text: 'Error starting creation process')
      end

      step 'The user can see the blocking overlay disappears when the process fails' do
        expect(page).to have_no_css('.test-bulk-upload-blur-screen', wait: 12)
      end
    end
  end
end
