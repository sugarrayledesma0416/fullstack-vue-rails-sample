feature 'Instructor Resources Export Tool', js: true, chrome: true do
  include CapybaraViewHelpers
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  describe 'As a resource editor' do
    let(:resource_editor) do
      create(:user).tap { |user| user.roles << Role.create!(name: Role::RESOURCE_EDITOR) }
    end
    let!(:program_1) { create(:program) }
    let!(:program_2) { create(:program) }
    let(:expected_download_link) { 'https://my_exported_file.zip' }
    let(:csv_signed_url) { 'https://my_exported_csv_file' }
    let(:last_modified) { 'Last creation date' }
    let(:file_size) { '300 MB' }
    let(:program_1_exporter) do
      instance_double(
        InstructorResourcesExport,
        {
          zip_exist_in_s3?: true,
          signed_url: expected_download_link,
          last_modified:,
          formatted_file_size: file_size,
          csv_exists_in_s3?: true
        }
      )
    end
    let(:program_2_exporter) do
      instance_double(
        InstructorResourcesExport,
        {
          zip_exist_in_s3?: false,
          signed_url: expected_download_link,
          last_modified:,
          formatted_file_size: file_size,
          csv_exists_in_s3?: false
        }
      )
    end

    before do
      stub_request(:get, csv_signed_url).to_return(
        status: 200,
        body: 'CSV content',
        headers: { 'Content-Type' => 'text/csv' }
      )
      allow(InstructorResourcesExport).to receive(:new)
        .with(program_1).and_return(program_1_exporter)
      allow(InstructorResourcesExport).to receive(:new)
        .with(program_2).and_return(program_2_exporter)
      log_in_as(resource_editor)
      allow(program_1_exporter).to receive(:set_file_path_to_zip)
      allow(program_1_exporter).to receive(:set_file_path_to_csv)
      allow(program_2_exporter).to receive(:set_file_path_to_zip)
      allow(program_2_exporter).to receive(:set_file_path_to_csv)
    end

    scenario 'When no program is selected initially' do
      visit index_instructor_resources_export_path
      purpose 'I see the export and csv buttons disabled' do
        expect(page).to have_button('Export', disabled: true)
        expect(page).to have_selector('#csv_button[disabled]')
      end
    end

    scenario 'When a program is selected for CSV export' do
      visit index_instructor_resources_export_path
      purpose 'I select a program and see the CSV button enabled' do
        page.select(program_1.title, from: 'program_id')
        expect(page).to have_button('Export', disabled: false)
        expect(page).to have_selector('#csv_button:not([disabled])')
      end

      purpose 'I click the CSV button and trigger the export' do
        page.find('.test-csv-button').click
        expect(page).to have_current_path(expected_download_link)
      end
    end

    scenario 'When a previous export file for the program has been created' do
      visit index_instructor_resources_export_path

      purpose "I select a program that previously had it's resources file created" do
        page.select(program_1.title, from: 'program_id')
        page.click_on('Export')

        step 'I see a link to refresh the zip file' do
          expect(page).to have_link('Update zip')
          expect(page).not_to have_link('Generate zip')
        end

        step 'I see a link to download the zip file from S3' do
          expect(page).to have_link('Download', href: expected_download_link)
        end

        step 'I see the file creation date' do
          expect(page).to have_selector('.test-zip-file-date', text: "This zip file was generated on #{last_modified}")
        end

        step 'I see the file size' do
          expect(page).to have_selector('.test-zip-file-size', text: "Download size: #{file_size}")
        end
      end
    end

    scenario 'When an export file for the program has not been created' do
      visit index_instructor_resources_export_path

      purpose "I select a program that has never had it's resources file created" do
        page.select(program_2.title, from: 'program_id')
        page.click_on('Export')

        step 'I see a link to generate the zip file' do
          expect(page).to have_link('Generate zip')
          expect(page).not_to have_link('Update zip')
        end

        step 'I do not see a link to download the zip file from S3' do
          expect(page).not_to have_link('Download', href: expected_download_link)
        end

        step 'I do not see the file creation date' do
          expect(page).not_to have_selector('.test-zip-file-date')
        end

        step 'I do not see the file size' do
          expect(page).not_to have_selector('.test-zip-file-size')
        end
      end

      purpose 'I generate the resource file' do
        page.click_on('Generate zip')
      end

      purpose 'I see links to return to the index page' do
        expect(page).to have_link('Return to export program', href: export_instructor_resources_export_path(program_id: program_2.id))
        expect(page).to have_link('Return to export tool', href: index_instructor_resources_export_path)
      end
    end
  end
end
