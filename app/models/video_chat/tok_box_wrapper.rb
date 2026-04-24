require 'opentok'

module VideoChat
  class TokBoxWrapper
    include StatsProcessor
    include DatadogProcessor
    include TimingEvents
    attr_reader :errors

    def initialize(user)
      @user = user
      @errors = { messages: [] }
    end

    private def api_key
      M3::Application.config.tokbox.fetch(:api_key, nil)
    end

    private def api_secret
      M3::Application.config.tokbox.fetch(:api_secret, nil)
    end

    private def tokbox
      return @tokbox if defined?(@tokbox)

      if api_key.nil? || api_secret.nil?
        @errors[:messages] << 'TokBox keys missing. Please, check the configuration file.'
        @tokbox = nil
      else
        @tokbox = OpenTok::OpenTok.new(api_key, api_secret)
      end
    end

    def get_session
      return if tokbox.nil?

      tokbox_session = time_event(:create_session) do
        tokbox.create_session(media_mode: :routed) # Routed means Use the Opentok Media Router.
      end

      log_session_stats(tokbox_session)

      { id: tokbox_session.session_id,
        status: :created,
        data: { api_key: tokbox_session.api_key,
                media_mode: tokbox_session.media_mode,
                archive_mode: tokbox_session.archive_mode }
      }

    rescue StandardError => e
      VHLMonitor.notify(e)
      log_session_stats(tokbox_session, e)
      @errors[:messages] << e.message
    end

    def get_token(session_id)
      return if tokbox.nil?

      tokbox_token = time_event(:get_token) do
        tokbox.generate_token(session_id,
                              expire_time: Time.now.to_i + (24 * 60 * 60), # 24 hours from now.
                              data: "username=#{@user.username},user_id=#{@user.id}", # Metadata. Up to 1000 chars long.
                              role: :publisher)
      end

      log_token_stats(tokbox_token)

      { id: tokbox_token, status: :created }

    rescue StandardError => e
      VHLMonitor.notify(e)

      log_token_stats(tokbox_token, e)
      @errors[:messages] << e.message
    end

    def record(session_id)
      recording = time_event(:recording_create) do
        tokbox.archives.create(session_id, output_mode: :composed)
      end

      log_recording_stats(session_id, recording, :recording_create)

      { id: recording.id, status: recording.status, data: { url: recording.url,
                                                            name: recording.name } }
    rescue StandardError => e
      VHLMonitor.notify(e)
      log_recording_stats(session_id, nil, :recording_create, e)
      @errors[:messages] << e.message
    end

    def stop_recording(session_id, recording_id)
      recording = time_event(:recording_stop) do
        tokbox.archives.stop_by_id(recording_id)
      end

      log_recording_stats(session_id, recording, :recording_stop)

      { id: recording.id, status: recording.status, data: { url: recording.url,
                                                            name: recording.name } }
    rescue StandardError => e
      VHLMonitor.notify(e)
      log_recording_stats(session_id, nil, :recording_stop, e)
      @errors[:messages] << e.message
    end

    def get_recording(session_id, recording_id)
      recording = time_event(:recording_find) do
        tokbox.archives.find(recording_id)
      end

      log_recording_stats(session_id, recording, :recording_find)

      # client wrapper (javascripts/chat/lib/cw-combine.js) expects an 'available' status and
      # TokBox returns 'uploaded' when we use S3 storage.
      status = case recording.status
               when 'available', 'uploaded' then 'available'
               when 'failed' then 'error'
               else
                 recording.status
               end

      {
        data: { name: recording.name, url: recording.url },
        id: recording.id,
        status: status
      }.tap do |memo|
        memo[:data][:reason] = recording.reason if recording.status == 'failed'
      end
    rescue StandardError => e
      VHLMonitor.notify(e)
      log_recording_stats(session_id, nil, :recording_find, e)
      @errors[:messages] << e.message
    end

    def errors?
      @errors[:messages].present?
    end

    private def log_session_stats(session, error = nil)
      # logstash
      data = {session_id: (session ? session.session_id : ''),
              user_id: @user.id,
              user_type: @user.base_account_type,
              latency: { duration: response_time[:create_session].to_i },
              service: 'tokbox',
              action: :session_create}

      dispatch(payload: data,
               stats_index: 'vhl-chat-server-tokbox',
               stats_type: :session_create,
               error: error)

      # datadog
      metric = 'chat.tokbox.session_create.latency'
      ddog_dispatch(metric: metric,
                    stats_type: :gauge,
                    role: 'session',
                    value: response_time[:create_session].to_i)
    end

    private def log_recording_stats(session_id, recording, recording_event, error = nil)
      if recording
        recording.extend RecordingStats
      else
        # this object provides logstash with a consistant set of values
        recording = MockRecording.new(session_id)
      end

      # logstash
      data = {}.tap do |hsh|
        hsh[:session_id] = recording.session_id
        hsh[:user_id] = @user.id
        hsh[:user_type] = @user.base_account_type
        hsh[:latency] = { duration: response_time[recording_event].to_i }
        hsh[:action] = recording_event
        hsh[:recording] = recording.attributes
        hsh[:service] = 'tokbox'
      end

      dispatch(payload: data,
               stats_index: 'vhl-chat-server-tokbox',
               stats_type: recording_event,
               error: error)

      # datadog
      metric = "chat.tokbox.#{recording_event}.latency"
      ddog_dispatch(metric: metric,
                    stats_type: :gauge,
                    role: 'video_recording',
                    value: response_time[recording_event].to_i)
    end

    private def log_token_stats(token, error = nil)
      data = {
        token: token,
        user_id: @user.id,
        user_type: @user.base_account_type,
        latency: { duration: response_time[:get_token].to_i },
        service: 'tokbox',
        action: :get_token }

      dispatch(payload: data,
               stats_index: 'vhl-chat-server-tokbox',
               stats_type: :get_token,
               error: error)

      # datadog
      metric = 'chat.tokbox.get_token.latency'
      ddog_dispatch(metric: metric,
                    stats_type: :gauge,
                    role: 'token',
                    value: response_time[:get_token].to_i)
    end
  end
end

module RecordingStats
  # a list of possible attributes in a OpenTok recording (Archive) object
  ATTRS = [:id, :duration, :created_at, :name, :has_audio, :has_video,
           :output_mode, :partner_id, :reason, :session_id, :size,
           :duration, :status, :url].freeze

  def attributes
    {}.tap do |hsh|
      ATTRS.each do |attr|
        begin
          hsh[attr] = send(attr)
        rescue NoMethodError
          hsh[attr] = nil
        end
      end
    end
  end
end

class MockRecording
  include RecordingStats
  attr_accessor :session_id

  def initialize(session_id)
    self.session_id = session_id
  end
end

