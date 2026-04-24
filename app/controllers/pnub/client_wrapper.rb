module Pnub
  class ClientWrapper
    DEFAULT_GRANTS_TTL = 1440 # 24 hours in minutes
    ACCESS_MANAGER_CHANNEL_LIMIT = 200

    attr_accessor :grants_ttl

    def initialize(user, activity_type = nil)
      @user = user
      @auth_token = SecureRandom.hex(10)
      @client = Pubnub.new(
        subscribe_key: sub_key,
        publish_key: pub_key,
        secret_key: M3::Application.config.pubnub[:sec_key],
        ssl: true,
        logger: Rails.logger,
        uuid: user.id.to_s
      )
      @grants_ttl = DEFAULT_GRANTS_TTL
      @activity_type = activity_type
    end

    def create_grants(opt_channels = [])
      return if groups_to_grant.empty?

      @grants = GrantCollection.new(
        ChannelSet.new(uuid, groups_to_grant, opt_channels),
        auth_token: @auth_token,
        client: @client,
        ttl: @grants_ttl
      )
      @grants.fire_grants
      @grants.send_latency_stats(@user)
      grants_successful?
    end

    def grants_successful?
      @grants&.success?
    end

    def grant_responses_with_errors
      @grants&.error_responses&.to_json
    end

    def chat_session_data
      client_roster.merge(
        auth_token: @auth_token,
        provider: 'pubnub',
        pubnub: { publish_key: pub_key, subscribe_key: sub_key },
        roster: { groups: chat_enabled_groups }
      )
    end

    def to_json
      chat_session_data.to_json
    end

    private def sub_key
      M3::Application.config.pubnub[:sub_key]
    end

    private def pub_key
      M3::Application.config.pubnub[:pub_key]
    end

    private def grants_roster
      @grants_roster ||= if @activity_type == 'solo_video_recording' && @user.student?
                           @user.active_courses_pubnub_grants_roster
                         else
                           @user.pubnub_grants_roster
                         end
    end

    private def client_roster
      @client_roster ||= @user.pubnub_client_roster
    end

    private def uuid
      @uuid ||= grants_roster[:user][:uuid]
    end

    private def groups_to_grant
      @groups_to_grant ||= grants_roster[:roster][:groups]
    end

    private def chat_enabled_groups
      @chat_enabled_groups ||= client_roster[:roster][:groups].reject do |group|
        group[:chat_level] == 'disabled'
      end
    end
  end

  class ChannelSet
    def initialize(uuid, groups, opt_channels = [])
      @uuid = uuid
      @groups = groups
      @opt_channels = opt_channels
    end

    def r_w_channels
      # This session channel is used by the partner chat flow. It needs read/write permissions.
      # We use gs_ as a short abbv. for group_session
      @groups.flat_map { |c| [c[:id], "gs_#{c[:id]}.*"] } + @opt_channels.map{ |channel| "gs_#{channel}" }
    end

    def write_channels
      # Control channels are used to track the user presence over a course/section
      # whereas history channels are used for message history (sending and retrieval).
      # We use gc_ as a short abbv. for group_control.
      # We use gt_ as a short abbv. for group_text.
      control_channels = @groups.map do |c|
        "gc_#{c[:id]}.*"
      end + @opt_channels.map { |channel| "gc_#{channel}" }

      history_channels = @groups.map do |c|
        "gt_#{c[:id]}.*"
      end + @opt_channels.map { |channel| "gt_#{channel}" }

      control_channels + history_channels
    end

    def read_channels
      # Control channels are used to track the user presence over a course/section
      # whereas history channels are used for message history (sending and retrieval).
      # We use gc_ as a short abbv. for group_control.
      # We use gt_ as a short abbv. for group_text.
      control_channels = @groups.flat_map do |channel|
        ["gc_#{channel[:id]}.#{@uuid}", "#{channel[:id]}-pnpres"]
      end + @opt_channels.map { |channel| "gc_#{channel}" }

      history_channels = @groups.flat_map do |channel|
        ["gt_#{channel[:id]}.#{@uuid}", "#{channel[:id]}-pnpres"]
      end + @opt_channels.map { |channel| "gt_#{channel}" }

      control_channels + history_channels
    end
  end

  class GrantCollection
    include LatencySender
    attr_accessor :error_responses

    def initialize(channels, grant_opts)
      @channels = channels
      @grant_opts = grant_opts
      @error_responses = []
    end

    def fire_grants
      grants.each do |grant|
        grant.grant
        unless grant.success
          @error_responses << grant.error_response
          break
        end
      end
    end

    def success?
      @sucess ||= grants.all?(&:success)
    end

    private def grants
      channels = rearrange_channels_for_read_write
      @grants ||= [
        ReadWriteGrant.new(channels[:r_w_channels], **@grant_opts),
        WriteGrant.new(channels[:write_channels], **@grant_opts),
        ReadGrant.new(channels[:read_channels], **@grant_opts)
      ]
    end

    # This method manipulates the grants channel array to call read&write grant together
    # for a channel which is intended for read and write grant both. As it seems that
    # a read grant overrides write grant if called on same channel.
    private def rearrange_channels_for_read_write
      read_channels = @channels.read_channels
      write_channels = @channels.write_channels
      r_w_channels = @channels.r_w_channels
      channels_in_both = read_channels & write_channels
      if channels_in_both.any?
        read_channels -= channels_in_both
        write_channels -= channels_in_both
        r_w_channels += channels_in_both
      end
      { read_channels: read_channels, write_channels: write_channels, r_w_channels: r_w_channels }
    end
  end

  class AbstractGrant
    include StatsProcessor
    include DatadogProcessor
    include TimingEvents

    attr_reader :success, :error_response

    def initialize(channels, auth_token:, client:, ttl: 1)
      @channels = channels
      @auth_token = auth_token
      @client = client
      @ttl = ttl
    end

    def grant(allow_read, allow_write)
      circuit_breaker.run! do
        @grant_response = time_event(grant_type) do
          options = grant_opts(allow_read, allow_write)
          # Do granting every 200 channels, so we don't hit the 200 limit on Access Manager
          @channels.each_slice(ClientWrapper::ACCESS_MANAGER_CHANNEL_LIMIT).map do |channels|
            @client.grant(options.merge(channels: channels))
          end
        end

        assign_results
      end
    rescue StandardError => e
      VHLMonitor.notify(e)
      @success = false
      @error_response = { code: 403, data: { message: e.message } }
    end

    def grant_latency
      response_time[grant_type]
    end

    # Configure state cache
    # https://github.com/yammer/circuitbox
    def circuit_breaker
      Circuitbox.circuit(
        :pubnub_grant,
        # seconds the circuit stays open once it has passed the error threshold
        sleep_window: 300, # default: 300

        # length of interval (in seconds) over which it calculates the error rate
        time_window: 60, # default: 60

        # number of requests within `time_window` seconds before it calculates error rates
        volume_threshold: 10, # default: 5 (from source. docs say 10 is default)

        # the store you want to use to save the circuit state so it can be
        # tracked, this needs to be Moneta compatible, and support increment
        cache: circuit_breaker_cache, # default: Moneta.new(:Memory)

        # exceeding this rate will open the circuit (percent)
        error_threshold: 50, # default: 50

        # seconds before the circuit times out
        timeout_seconds: 5.0 # default: 1
      )
    end

    private def circuit_breaker_cache
      if M3::Application.config.cb_cache.is_a?(Moneta::Transformer)
        M3::Application.config.cb_cache
      else
        Moneta.new(:Memory)
      end
    end

    private def grant_opts(allow_read, allow_write)
      {
        auth_key: @auth_token,
        channels: @channels,
        http_sync: true,
        manage: false,
        read: allow_read,
        ttl: @ttl,
        write: allow_write
      }
    end

    def assign_results
      @success = @grant_response.all? { |res| res.status && res.status[:code] == 200 }
      @error_response = @grant_response.flat_map(&:result) unless @success
    end
  end

  class ReadWriteGrant < AbstractGrant
    def grant_type
      'read_write_grant'.freeze
    end

    def grant
      super(true, true)
    end
  end

  class WriteGrant < AbstractGrant
    def grant_type
      'write_grant'.freeze
    end

    def grant
      super(false, true)
    end
  end

  class ReadGrant < AbstractGrant
    def grant_type
      'read_grant'.freeze
    end

    def grant
      super(true, false)
    end
  end
end
