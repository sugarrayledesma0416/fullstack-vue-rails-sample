class RecordingConfiguration
  CONFIG_FILE_PATH = if Rails.env.test?
                       Rails.root.join('spec', 'fixtures', 'recording_server_config.yml')
                     else
                       Rails.root.join('config', 'recording_server.yml')
                     end

  MISSING_FILE_MESSAGE = "no recording server configuration file found at #{CONFIG_FILE_PATH}"

  def initialize
    fail MISSING_FILE_MESSAGE unless File.exist? CONFIG_FILE_PATH
    yaml_config = load_config_file
    @video_host = yaml_config['video_host']
    @video_application = yaml_config['video_application']
    @wowza_server_host = yaml_config['wowza_server_url']
    @load_balancer_url = yaml_config['load_balancer_url']
  end

  def server_host
    # Wowza will be our recording server now
    wowza_server_host
  end

  def wowza_server_host
    "#{@wowza_server_host}"
  end

  def load_balancer_url(server_url = '')
    if fms_server?(server_url)
      ''
    else
      @load_balancer_url
    end
  end

  def fms_server?(_server_url)
    # there is no FMS server as of jul 2015
    false
  end

  def playback_server_url(file_path)
    # Wowza is our recording server now
    wowza_server_host
  end

  def video_playback_url
    Rails.application.config.multimedia.instructor_created_activities.cdn_prefix + "old_vre"
  end

  def video_settings
    {
      load_balancer_url: @load_balancer_url,
      host: @video_host,
      application: @video_application,
      connect_on_init: true,
      format: 'mp4'
    }
  end

  def load_config_file
    configuration = YAML.load_file(CONFIG_FILE_PATH)

    if configuration.empty?
      fail "no environments found in recording server configuration file #{CONFIG_FILE_PATH}"
    end

    env_config = configuration[Rails.env]

    if env_config.blank?
      fail "recording server configuration file #{CONFIG_FILE_PATH} has no data for #{Rails.env} env."
    end

    env_config
  end
  private :load_config_file
end
