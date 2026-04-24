feature 'A11y Report Generator Tool', js: true, chrome: true do
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
    let(:detailed_last_modified) { 'some date' }
    let(:simplified_last_modified) { 'some other date' }
    let(:simplified_url) { 'http://simplified_report/' }
    let(:detailed_url) { 'http://detailed_report/' }
    let(:program_1_exporter) do
      instance_double(
        A11yReportGenerator,
        simplified_report_url: simplified_url,
        detailed_report_url: detailed_url,
        simplified_report_last_modified: simplified_last_modified,
        detailed_report_last_modified: detailed_last_modified
      )
    end
    let(:program_2_exporter) do
      instance_double(
        A11yReportGenerator,
        simplified_report_url: nil,
        detailed_report_url: nil,
        simplified_report_last_modified: nil,
        detailed_report_last_modified: nil
      )
    end

    before do
      allow(A11yReportGenerator).to receive(:new).with(program_1.id).and_return(program_1_exporter)
      allow(A11yReportGenerator).to receive(:new).with(program_2.id).and_return(program_2_exporter)
      log_in_as(resource_editor)
    end

    scenario 'When a program has A11y Reports Previously Generated' do
      visit index_a11y_report_generator_path

      purpose "I select a program that previously had it's report file created" do
        page.select(program_1.title, from: 'program_id')
        page.click_on('Export')

        step 'I see links to refresh the report files' do
          expect(page).to have_selector('.test-update-detailed')
          expect(page).to have_selector('.test-update-simplified')
          expect(page).not_to have_selector('.test-generate-detailed')
          expect(page).not_to have_selector('.test-generate-simplified')
        end

        step 'I see links to download the report files from S3' do
          expect(page).to have_link('Download',
                                    href: detailed_url)
          expect(page).to have_link('Download',
                                    href: simplified_url)
        end

        step 'I see the file creation date of the reports' do
          expect(page).to have_selector('.test-detailed-report-date',
                                        text: "This report was generated: #{detailed_last_modified}")
          expect(page).to have_selector('.test-simplified-report-date',
                                        text: "This report was generated: #{simplified_last_modified}")
        end
      end
    end

    scenario 'When an A11y report file for the program has not been created' do
      visit index_a11y_report_generator_path

      purpose "I select a program that has never had it's report files created" do
        page.select(program_2.title, from: 'program_id')
        page.click_on('Export')

        step 'I see a link to generate the report files' do
          expect(page).to have_link('Generate Simplified Report')
          expect(page).to have_link('Generate Detailed Report')
          expect(page).not_to have_link('Update Report')
        end

        step 'I do not see a link to download any report file' do
          expect(page).not_to have_selector('.test-download-detailed')
          expect(page).not_to have_selector('.test-download-simplified')
        end

        step 'I do not see the file creation date' do
          expect(page).not_to have_selector('.test-detailed-report-date')
          expect(page).not_to have_selector('.test-simplified-report-date')
        end
      end

      purpose 'I generate a report file' do
        page.click_on('Generate Detailed Report')
      end

      purpose 'I see links to return to the index page' do
        expect(page).to have_link('Return to A11y Report Tool',
                                  href: index_a11y_report_generator_path)
        expect(page).to have_link('Return to Program Report',
                                  href: report_a11y_report_generator_path(program_id: program_2.id))
      end
    end
  end
end
