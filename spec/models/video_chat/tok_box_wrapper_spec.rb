describe VideoChat::TokBoxWrapper do
  let(:user) { build_stubbed(:student) }
  let(:wrapper) { described_class.new(user) }
  let(:session_id) do
    '1_MX4xMjM0NTZ-fk1vbiBNYXIgMTcgMDA6NDE6MzEgUERUIDIwMTR-MC42ODM3ODk1MzQ0OTQyODA4fg'
  end

  let(:recording_id) do
    '30b3ebf1-ba36-4f5b-8def-6f70d9986fe9'
  end

  before do
    allow_any_instance_of(described_class).to receive(:api_key).and_return('123456')
    allow_any_instance_of(described_class).to receive(:api_secret)
      .and_return('1234567890abcdef1234567890abcdef1234567890')

    allow(VHLMonitor).to receive(:notify)

    # Response grabbed from
    # https://github.com/opentok/OpenTok-Ruby-SDK/blob/master/spec/cassettes/OpenTok_OpenTok/when_initialized_properly/_create_session/creates_default_sessions.yml
    stub_request(:post, 'https://api.opentok.com/session/create')
      .to_return(status: 200, body: '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><sessions><Session><session_id>1_MX4xMjM0NTZ-fk1vbiBNYXIgMTcgMDA6NDE6MzEgUERUIDIwMTR-MC42ODM3ODk1MzQ0OTQyODA4fg</session_id><partner_id>123456</partner_id><create_dt>Mon Mar 17 00:41:31 PDT 2014</create_dt></Session></sessions>', headers: { 'Content-Type' => 'text/xml' })

    # Response grabbed from
    # https://github.com/opentok/OpenTok-Ruby-SDK/blob/master/spec/cassettes/OpenTok_Archives/should_stop_archives.yml
    stub_request(:post, "https://api.opentok.com/v2/project/123456/archive/#{recording_id}/stop")
      .to_return(status: 200,
                headers: { 'Content-Type' => 'application/json' },
                body: %Q[{ "createdAt" : 1395183243556,
                "duration" : 0,
                "id" : "30b3ebf1-ba36-4f5b-8def-6f70d9986fe9",
                "name" : "",
                "partnerId" : 123456,
                "reason" : "",
                "sessionId" : "#{session_id}",
                "size" : 0,
                "status" : "stopped",
                "url" : null }])

    # Response grabbed from
    # https://github.com/opentok/OpenTok-Ruby-SDK/blob/master/spec/cassettes/OpenTok_Archives/should_create_archives.yml
    stub_request(:post, "https://api.opentok.com/v2/project/123456/archive")
      .to_return(status: 200,
                headers: { 'Content-Type' => 'application/json' },
                body: %Q[{ "createdAt" : 1395183243556,
                "duration" : 0,
                "id" : "30b3ebf1-ba36-4f5b-8def-6f70d9986fe9",
                "name" : "",
                "partnerId" : 123456,
                "reason" : "",
                "sessionId" : "#{session_id}",
                "size" : 0,
                "status" : "started",
                "url" : null }])

    stub_request(:get, "https://api.opentok.com/v2/project/123456/archive/#{recording_id}")
      .to_return({ headers: { 'Content-Type' => 'application/json' },
                  status: 200,
                  body: %Q[{ "createdAt" : 1395183243556,
                              "duration" : 0,
                              "id" : "30b3ebf1-ba36-4f5b-8def-6f70d9986fe9",
                              "name" : "",
                              "partnerId" : 123456,
                              "reason" : "",
                              "sessionId" : "#{session_id}",
                              "size" : 0,
                              "status" : "started",
                              "url" : null }] })
  end

  describe '#get_session' do
    it 'tries to create a session id using the "routed" media mode' do
      expect_any_instance_of(OpenTok::OpenTok).to receive(:create_session)
        .with(media_mode: :routed)

      wrapper.get_session
    end

    it 'returns a hash with the session id and the respective status' do
      result = wrapper.get_session

      expect(result[:id]).to eq session_id
      expect(result[:status]).to eq :created
    end

    it 'saves the exception message when something wrong happens' do
      expect_any_instance_of(OpenTok::OpenTok).to receive(:create_session).and_raise('WrongTokbox')

      wrapper.get_session # Trigger the error

      expect(wrapper.errors?).to be true
      expect(wrapper.errors).to eq messages: ['WrongTokbox']
    end
  end

  describe '#get_token' do

    it 'tries to generate a new token based on the specified session id' do
      expect_any_instance_of(OpenTok::OpenTok).to receive(:generate_token)
        .with(session_id, expire_time: anything, data: "username=#{user.username},user_id=#{user.id}", role: :publisher)

      wrapper.get_token(session_id)
    end

    it 'returns a hash with a valid generated token and status' do
      result = wrapper.get_token(session_id)

      # This string is calculated using the sessionId and api secret.
      # Because we have in the test an static sessionId and api secret, the calculated string won't
      # change

      token_header = 'T1==cGFydG5lcl9pZD0xMjM0NTYmc2ln'

      expect(result[:id]).to include token_header
      expect(result[:status]).to eq :created
    end

    it 'saves the exception message when something wrong happens' do
      expect_any_instance_of(OpenTok::OpenTok).to receive(:generate_token).and_raise('WrongTokbox')

      wrapper.get_token(session_id) # Trigger the error

      expect(wrapper.errors?).to be true
      expect(wrapper.errors).to eq messages: ['WrongTokbox']
    end
  end

  describe '#record' do
    it 'returns the id and additional information of the archive process that is in progress' do
      expect(wrapper.record(session_id)).to eq({ id: recording_id,
                                             status: 'started',
                                               data: { url: nil, name: '' } })
    end

    it 'sends stats data' do
      expect(wrapper).to receive(:log_recording_stats).and_call_original
      expect(wrapper).to receive(:dispatch) do |data|
        expect(data[:payload][:session_id]).to eq session_id
        expect(data[:payload][:recording].keys).to eq([:id, :duration,
          :created_at, :name, :has_audio, :has_video, :output_mode,
          :partner_id, :reason, :session_id, :size, :status, :url])
      end
      wrapper.record(session_id)
    end

    it 'sends latency data to datadog' do
      expect(wrapper).to receive(:ddog_dispatch)
        .with(metric: 'chat.tokbox.recording_create.latency',
              stats_type: :gauge,
              role: 'video_recording',
              value: anything )
      wrapper.record(session_id)
    end
  end

  describe '#stop_recording' do
    it 'stops the recording for an ongoing recording' do
      expect_any_instance_of(OpenTok::Archives).to receive(:stop_by_id)

      wrapper.stop_recording(session_id, recording_id)
    end

    it 'returns the id and additional information of the archive process that just stopped' do
      expect(wrapper.stop_recording(session_id, recording_id)).to eq({ id: recording_id,
                                                       status: 'stopped',
                                                         data: { url: nil, name: '' } })
    end

    it 'sends stats data' do
      expect(wrapper).to receive(:log_recording_stats).and_call_original
      expect(wrapper).to receive(:dispatch) do |data|
        expect(data[:payload][:session_id]).to eq session_id
        expect(data[:payload][:recording].keys).to eq([:id, :duration,
          :created_at, :name, :has_audio, :has_video, :output_mode,
          :partner_id, :reason, :session_id, :size, :status, :url])
      end
      wrapper.stop_recording(session_id, recording_id)
    end

    it 'sends latency data to datadog' do
      expect(wrapper).to receive(:ddog_dispatch)
        .with(metric: 'chat.tokbox.recording_stop.latency',
              stats_type: :gauge,
              role: 'video_recording',
              value: anything )
      wrapper.stop_recording(session_id, recording_id)
    end
  end

  describe '#get_recording' do
    let(:default_body_attrs) do
      { createdAt: 1395183243556,
        duration: 0,
        id: recording_id,
        name: "",
        partnerId: 123456,
        reason: "",
        sessionId: "#{session_id}",
        size: 0,
        status: "started",
        url: nil }
    end

    def generate_tokbox_response(attrs = {})
      {
        headers: { 'Content-Type' => 'application/json' },
        status: 200,
        body: default_body_attrs.merge(attrs).to_json
      }
    end

    it 'returns the id and additional information of a recording' do
      stub_request(:get, "https://api.opentok.com/v2/project/123456/archive/#{recording_id}")
        .to_return(generate_tokbox_response)

      received_response = wrapper.get_recording(session_id, recording_id)
      expected_response = { id: recording_id, status: 'started', data: { name: '', url: nil } }

      expect(received_response).to eq(expected_response)
    end

    it "returns an 'available' status when status response from tokbox is 'uploaded'" do
      stub_request(:get, "https://api.opentok.com/v2/project/123456/archive/#{recording_id}")
        .to_return(generate_tokbox_response(status: 'uploaded'))

      response = wrapper.get_recording(session_id, recording_id)
      expect(response[:status]).to eq('available')
    end

    it "passes the tokbox status if is not 'uploaded' or 'available'" do
      other_status = 'stopped'
      stub_request(:get, "https://api.opentok.com/v2/project/123456/archive/#{recording_id}")
        .to_return(generate_tokbox_response(status: other_status))

      response = wrapper.get_recording(session_id, recording_id)

      expect(response[:status]).to eq(other_status)
    end

    it "returns an error status if tokbox status is 'failed'" do
      stub_request(:get, "https://api.opentok.com/v2/project/123456/archive/#{recording_id}")
        .to_return(generate_tokbox_response(status: 'failed'))

      response = wrapper.get_recording(session_id, recording_id)
      expect(response[:status]).to eq('error')
    end

    it "appends the tokbox reason to the response when we receive a 'failed' status from tokbox" do
      reason = 'Too much data has been sent for processing. We cannot recover from that'

      stub_request(:get, "https://api.opentok.com/v2/project/123456/archive/#{recording_id}")
        .to_return(generate_tokbox_response(reason: reason, status: 'failed'))

      response = wrapper.get_recording(session_id, recording_id)
      expect(response[:data][:reason]).to eq(reason)
    end

    it 'sends stats data' do
      expect(wrapper).to receive(:log_recording_stats).and_call_original
      expect(wrapper).to receive(:dispatch) do |data|
        expect(data[:payload][:session_id]).to eq session_id
        expect(data[:payload][:recording].keys).to eq([:id, :duration,
          :created_at, :name, :has_audio, :has_video, :output_mode,
          :partner_id, :reason, :session_id, :size, :status, :url])
      end
      wrapper.get_recording(session_id, recording_id)
    end

    it 'sends latency data to datadog' do
      expect(wrapper).to receive(:ddog_dispatch)
        .with(metric: 'chat.tokbox.recording_find.latency',
              stats_type: :gauge,
              role: 'video_recording',
              value: anything )
      wrapper.get_recording(session_id, recording_id)
    end
  end

  describe '#errors?' do
    it 'returns true when one of the required keys are missing' do
      allow_any_instance_of(described_class).to receive(:api_key) # Return nil

      wrapper.get_session # Trigger the validation

      expect(wrapper.errors?).to be true
    end

    it 'returns true when something wrong happened' do
      allow(OpenTok::OpenTok).to receive(:new).and_raise('Wrong!')

      wrapper.get_session # Trigger the error

      expect(wrapper.errors?).to be true
    end
  end
end
