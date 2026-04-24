feature 'sidebar', chrome: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program, family: 'vista_online_learning') }

  before do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  it 'will redirect to media location ini the S3 bucket', js: true do
    file_name = 'file_name.jpg'
    visit "/media/games/#{file_name}"
    expect(current_path).to eq  "/zip_contents/#{file_name}"
  end

  it 'will not generate and error if the file name contains spaces', js: true do
    file_name = CGI.escape('file name with spaces.mp3')
    visit "/media/games/#{file_name}"
    expect(current_path).to eq  "/zip_contents/#{file_name}"
  end

  it 'accepts image and mp3 files', js: true do
    valid_extensions = %w(gif jpg png mp3)
    base_file_name = 'file_name'
    valid_extensions.each do |valid_extension|
      expect{ visit "/media/games/#{base_file_name}.#{valid_extension}" }.not_to raise_error
    end
  end

  it 'does not accept files that are not images or mp3s' do
    other_extensions = %w(xml key crt)
    base_file_name = 'file_name'
    other_extensions.each do |other_extension|
      expect{ visit "/media/games/#{base_file_name}.#{other_extension}" }.to raise_error(ActionController::RoutingError)
    end
  end
end
