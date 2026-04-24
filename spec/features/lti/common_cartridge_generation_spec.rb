feature 'common cartridge generation', js: true, chrome: true do
  include RspecJsApiHelpers
  include RspecJsCommonHelpers

  let(:support_rep) { create(:support_rep_user) }
  let(:programs) { create_list(:program, 10) }
  let(:packages) do
    programs.map.with_index do |program, index|
      init_val = 100 * (index + 1)
      end_val = init_val + 100
      instance_double(Maestro::PackageContent, id: SecureRandom.random_number(init_val..end_val),
                                               program_id: program.id)
    end
  end

  before do
    create_list(:program, 5)
    allow(Maestro::PackageContent).to receive(:with_common_cartridge).and_return(packages)
  end

  scenario 'list programs alphabetically' do
    purpose 'when I visit the common cartridge generation page I should see' \
      'the list of programs in alphabetical order' do

      step 'login as support rep user' do
        initialize_client_calls_for_user(support_rep)
        log_in_as(support_rep)
      end

      step 'visit the common cartridge generation page' do
        visit cartridge_support_programs_path
      end

      step 'check the list of programs sorted alphabetically' do
        expect(page.all('.test-program').collect(&:text)).to eq programs.map(&:title).sort
      end
    end
  end

  scenario 'display only common cartridge programs' do
    purpose 'when I visit the common cartridge generation page I should see' \
      'only common cartridge programs' do

      step 'login as support rep user' do
        initialize_client_calls_for_user(support_rep)
        log_in_as(support_rep)
      end

      step 'visit the common cartridge generation page' do
        visit cartridge_support_programs_path
      end

      step 'display only common cartridge programs' do
        expect(page.all('.test-program').collect(&:text).count).to eq programs.size
        expect(Maestro::PackageContent).to have_received(:with_common_cartridge)
      end
    end
  end
end
