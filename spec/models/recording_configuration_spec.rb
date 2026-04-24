describe RecordingConfiguration, core: true do
  let(:wowza_server_url) { 'http://valid_recording_server/url' }

  let(:data_from_yaml) do
    { Rails.env => { 'wowza_server_url' => wowza_server_url,
                     'load_balancer_url' => '/load_balancer_url',
                     'video_host' => 'arc-staging.chat.vhlcentral.com',
                     'video_application' => 'vre' }
    }
  end

  let(:server_url) { 'http://valid_server/url' }

  before do
    allow(File).to receive(:exist?).with(RecordingConfiguration::CONFIG_FILE_PATH).and_return(true)
    allow(YAML).to receive(:load_file).with(RecordingConfiguration::CONFIG_FILE_PATH).and_return(data_from_yaml)
  end

  it 'loads the recording server config file from the fixtures path when is test environment' do
    file_path = 'spec/fixtures/recording_server_config.yml'

    expect(RecordingConfiguration::CONFIG_FILE_PATH.to_s).to match(/#{file_path}/)
  end

  it 'fails when the configuration file does not exists' do
    allow(File).to receive(:exist?).with(RecordingConfiguration::CONFIG_FILE_PATH).and_return(false)

    expect { described_class.new }
      .to raise_error(RuntimeError, /no recording server configuration file found/)
  end

  it 'fails when the YAML file has missing information' do
    allow(YAML).to receive(:load_file)
      .with(RecordingConfiguration::CONFIG_FILE_PATH).and_return(Rails.env => {})

    expect { described_class.new }
      .to raise_error(RuntimeError, /recording server configuration file .*recording_server_config.yml has no data for \w+ env./)
  end

  describe '#video_playback_url' do
    it 'returns a video playback url' do
      config = RecordingConfiguration.new
      expect(config.video_playback_url).to eq(Rails.application.config.multimedia.instructor_created_activities.cdn_prefix + "old_vre")
    end
  end

  describe '#load_balancer_url' do
    it 'returns load_balancer_ur' do
      expect(RecordingConfiguration.new.load_balancer_url('')).to eq('/load_balancer_url')
      expect(RecordingConfiguration.new.load_balancer_url(wowza_server_url)).to eq('/load_balancer_url')
    end
  end

  describe '#playback_server_url' do
    let(:recording_config){ RecordingConfiguration.new }

    it 'returns wowza server url when file path match the new format' do
      file_path = '/m3_student_attempts/a0b/216/0c7/4dd/a0b2160c-74dd-4396-b916-3efb9d5309a1'
      expect(recording_config.playback_server_url(file_path)).to match(/#{wowza_server_url}/)
    end
  end
end
