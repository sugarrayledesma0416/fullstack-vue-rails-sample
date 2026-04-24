feature 'Cartridge exporter', chrome: true, js: true, downloads: true do
  include RspecJsCommonHelpers
  include CapybaraViewHelpers
  include RspecJsApiHelpers
  include CapybaraViewHelpers
  # Include application helpers for time formatting methods
  include ApplicationHelper

  let(:program) { create(:program) }
  let(:common_cartridge_creator) { create(:support_rep_user) }

  before do
    allow(Aws::CF::Signer).to receive(:sign_url) do |params|
      params + '.signed'
    end
    allow(Maestro::PackageContent).to receive(
      :with_common_cartridge
    ).and_return(
      [instance_double(Maestro::PackageContent, program_id: program.id)]
    )
    allow(Cartridge::ExporterWorker).to receive(:perform_async)

    initialize_program_access_client_calls_for_user_and_program(
      common_cartridge_creator, program
    )
    log_in_as(common_cartridge_creator)
  end

  scenario 'As a tech prod user, I can export a program as a cartridge' do
    cartridge_1 = create(
      :cartridge_build_status,
      cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0,
      program: program
    )
    cartridge_2 = create(
      :cartridge_failed_build_status,
      cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_2_0,
      program: program
    )
    cartridge_3 = create(
      :cartridge_build_status,
      cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_3_0,
      program: program
    )
    cartridge_4 = create(
      :cartridge_failed_build_status,
      cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_3_0,
      program: program
    )

    purpose 'I select a program to export from' do
      visit cartridge_support_programs_path
      click_on(program.title)
    end

    purpose 'I see all the existing cartridges separated by version' do
      within('.c-panel[data-test-cc_version="1.1.0"]') do
        expect(page).to have_no_selector('.test-failed_cartridge')

        expect(page).to have_selector(
          '.test-valid_cartridge',
          text: 'Download the latest valid cartridge, created on ' \
                "#{format_date_time(cartridge_1.created_at, :standard)} by " \
                "#{cartridge_1.creator.full_name}."
        )
        expect(page).to have_link('Download', href: cartridge_1.signed_url)
      end

      within('.c-panel[data-test-cc_version="1.2.0"]') do
        expect(page).to have_selector(
          '.test-failed_cartridge',
          text: 'Last cartridge created on ' \
                "#{format_date_time(cartridge_2.created_at, :standard)} by " \
                "#{cartridge_2.creator.full_name} failed: " \
                "#{cartridge_2.error_message}"
        )

        expect(page).to have_selector(
          '.test-no_valid_cartridge',
          text: 'There is currently no valid cartridge to download.'
        )
        expect(page).to have_no_link('Download')
      end

      within('.c-panel[data-test-cc_version="1.3.0"]') do
        expect(page).to have_selector(
          '.test-failed_cartridge',
          text: 'Last cartridge created on ' \
                "#{format_date_time(cartridge_4.created_at, :standard)} by " \
                "#{cartridge_4.creator.full_name} failed: " \
                "#{cartridge_4.error_message}"
        )

        expect(page).to have_selector(
          '.test-valid_cartridge',
          text: 'Download the latest valid cartridge, created on ' \
                "#{format_date_time(cartridge_3.created_at, :standard)} by " \
                "#{cartridge_3.creator.full_name}."
        )
        expect(page).to have_link('Download', href: cartridge_3.signed_url)
      end
    end

    purpose 'I can download an existing cartridge' do
      within('.c-panel[data-test-cc_version="1.1.0"]') do
        expect(page).to have_link('Download', href: cartridge_1.signed_url)
      end
    end

    purpose 'I export a new cartridge' do
      within('.c-panel[data-test-cc_version="1.1.0"]') do
        click_on('Generate a new cartridge')
      end

      expect_flash_message(
        :notice,
        "The common cartridge export for #{program.title} " \
        'version 1.1.0 has been scheduled.'
      )

      expect(Cartridge::ExporterWorker).to have_received(:perform_async).with(
        program.id, common_cartridge_creator.id, '1.1.0'
      )
    end
  end
end
