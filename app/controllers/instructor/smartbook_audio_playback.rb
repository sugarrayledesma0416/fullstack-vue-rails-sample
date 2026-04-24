module Instructor::SmartbookAudioPlayback
  # Convert a smartbook audio recording URL to the corresponding playback URL.
  # original URL: https://lossless.qa.vhlcentral.com/smartbook/7397fe33-f374-4c55-ba99-e7cf908d8b5d/e7f51719-5ead-4982-bc65-528172666ebf/VR_SBDED/U1S1D1A/2019266160353062.wav
  #   - Original section guid: 7397fe33-f374-4c55-ba99-e7cf908d8b5d correspond
  #   -  Original token: e7f51719-5ead-4982-bc65-528172666ebf
  #   - File path: VR_SBDED/U1S1D1A/2019266160353062.wav
  # Playback URL: https://lossless.qa.vhlcentral.com/smartbook/<section_guid>/<playback_token>/VR_SBDED/U1S1D1A/2019266160353062.wav
  def smartbook_audio_playback_url(original_path)
    if original_path.starts_with?(Smartbook::Response::SANTILLANA_BUCKET_PREFIX)
      original_path
    elsif @lossless_auth_token
      base_endpoint = Rails.application.config.smartbook_recording_endpoint
      section = current_section.guid
      token = @lossless_auth_token
      lossless_endpoint = base_endpoint + '/' + section + '/' + token
      # When we split the original path using the '/' separator, we end up with
      # an array like:
      # ['', 'smartbook', 'section_guid', 'token', 'VR_SBDED', 'U1S1D1A', '2019266160353062.wav']
      # So we skip the 4 first elements of the array to build the playback url.
      lossless_endpoint + '/' + URI(original_path).path.split('/')[4..-1].join('/')
    else
      ''
    end
  end

  def self.included(klass)
    klass.helper_method :smartbook_audio_playback_url
  end
end
