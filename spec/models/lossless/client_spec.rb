describe Lossless::Client do
  let(:fake_password) { 'abcdef' }
  let(:api_host) { M3::Application.config.lossless_base_url }

  before do
    M3::Application.config.lossless_api_password = fake_password
    allow(VHLMonitor).to receive(:notify)
    allow(VHLMonitor).to receive(:error)
  end

  describe '#get_token' do
    let(:cache_key) { 'abc' }
    let(:endpoint) { "#{api_host}/m3/policy/#{cache_key}" }

    it 'makes a get request containing the specified cache key' do
      stub_request(:get, endpoint).to_return(
        status: 200, body: '', headers: {}
      )

      described_class.new.get_token(cache_key)

      expect(a_request(:get, endpoint)).to have_been_made
    end

    context 'when the response is successful,' do
      it 'returns the token key from the response body if it is set' do
        stub_request(:get, endpoint).to_return(
          body: { token: 'abc' }.to_json,
          headers: { 'Content-Type' => 'application/json' },
          status: 200
        )

        expect(described_class.new.get_token(cache_key)).to eq('abc')
      end

      it 'returns an empty string if the response body has no token key' do
        stub_request(:get, endpoint).to_return(
          body: {}.to_json,
          headers: { 'Content-Type' => 'application/json' },
          status: 200
        )

        expect(described_class.new.get_token(cache_key)).to eq('')
      end
    end

    context 'when the response has an error status,' do
      before do
        stub_request(:get, endpoint).to_return(
          status: 401, body: 'Not authorized', headers: {}
        )
      end

      it 'sends the error and request details to VHLMonitor' do
        described_class.new.get_token(cache_key)

        expect(VHLMonitor).to have_received(:error).with(
          response: hash_including(
            response_body: 'Not authorized', status: 401
          ),
          request: { path: "/m3/policy/#{cache_key}", verb: :get }
        )
      end

      it 'removes the response key from the faraday response sent to VHLMonitor ' \
         'to prevent infinite recursion when json tries to serialize it' do
        described_class.new.get_token(cache_key)

        expect(VHLMonitor).to have_received(:error).with(
          response: hash_excluding(:response),
          request: { path: "/m3/policy/#{cache_key}", verb: :get }
        )
      end

      it 'returns nil' do
        expect(described_class.new.get_token(cache_key)).to be_nil
      end
    end

    context 'when the request raises an exception,' do
      let(:error) { StandardError.new('some network problem') }

      before do
        stub_request(:get, /#{endpoint}.*/).to_raise(error)
      end

      it 'sends the exception and request details to VHLMonitor' do
        described_class.new.get_token(cache_key)

        expect(VHLMonitor).to have_received(:notify).with(
          error,
          request: { path: "/m3/policy/#{cache_key}", verb: :get }
        )
      end

      it 'returns nil' do
        expect(described_class.new.get_token(cache_key)).to be_nil
      end
    end
  end

  describe '#send_policy' do
    let(:policy) { { my: :policy }.to_json }
    let(:endpoint) { "#{api_host}/m3/policy" }

    it 'makes a post request with the specified policy' do
      stub_request(:post, /#{endpoint}.*/).to_return(
        status: 200, body: '', headers: {}
      )

      described_class.new.send_policy(policy)

      expect(a_request(:post, endpoint).with(body: policy)).to have_been_made
    end

    context 'when the response is successful,' do
      it 'returns the token key from the response body if it is set' do
        stub_request(:post, /#{endpoint}.*/).to_return(
          body: { token: 'abc' }.to_json,
          headers: { 'Content-Type' => 'application/json' },
          status: 200
        )

        expect(described_class.new.send_policy(policy)).to eq('abc')
      end

      it 'returns an empty string if the response body has no token key' do
        stub_request(:post, /#{endpoint}.*/).to_return(
          body: {}.to_json,
          headers: { 'Content-Type' => 'application/json' },
          status: 200
        )

        expect(described_class.new.send_policy(policy)).to eq('')
      end
    end

    context 'when the response has an error status,' do
      before do
        stub_request(:post, /#{endpoint}.*/).to_return(
          status: 401, body: 'Not authorized', headers: {}
        )
      end

      it 'sends the error and request details to VHLMonitor' do
        described_class.new.send_policy(policy)

        expect(VHLMonitor).to have_received(:error).with(
          response: hash_including(
            response_body: 'Not authorized', status: 401
          ),
          request: {
            body: policy, path: '/m3/policy', verb: :post
          }
        )
      end

      it 'returns nil' do
        expect(described_class.new.send_policy(policy)).to be_nil
      end
    end

    context 'when the request raises an exception,' do
      let(:error) { StandardError.new('some network problem') }

      before do
        stub_request(:post, /#{endpoint}.*/).to_raise(error)
      end

      it 'sends the exception and request details to VHLMonitor' do
        described_class.new.send_policy(policy)

        expect(VHLMonitor).to have_received(:notify).with(
          error,
          request: {
            body: policy, path: '/m3/policy', verb: :post
          }
        )
      end

      it 'returns nil' do
        expect(described_class.new.send_policy(policy)).to be_nil
      end
    end
  end

  describe '#delete_user_data' do
    let(:user_id) { 123 }
    let(:path) { "/m3/delete_user_data/#{user_id}" }
    let(:endpoint) { api_host + path }

    it 'makes a post request to the correct endpoint' do
      stub_request(:post, endpoint).to_return(status: 200)
      described_class.new.delete_user_data(user_id)
      expect(a_request(:post, endpoint)).to have_been_made
    end

    context 'when the response is successful,' do
      it 'returns true' do
        stub_request(:post, endpoint).to_return(status: 200)
        expect(described_class.new.delete_user_data(user_id)).to eq(true)
      end
    end

    context 'when the response has an error status,' do
      it 'sends the error and request details to VHLMonitor' do
        stub_request(:post, endpoint).to_return(
          status: 401,
          body: 'Not authorized'
        )
        described_class.new.delete_user_data(user_id)
        expect(VHLMonitor).to have_received(:error).with(
          response: hash_including(
            response_body: 'Not authorized',
            status: 401
          ),
          request: {
            path: path,
            verb: :post
          }
        )
      end
    end

    context 'when the request raises an exception,' do
      it 'sends the exception and request details to VHLMonitor' do
        error = StandardError.new('some network problem')
        stub_request(:post, endpoint).to_raise(error)
        described_class.new.delete_user_data(user_id)
        expect(VHLMonitor).to have_received(:notify).with(
          error,
          request: {
            path: path,
            verb: :post
          }
        )
      end
    end
  end

  describe '#delete_school_data' do
    let(:school_id) { 123 }
    let(:path) { "/m3/delete_school_data/#{school_id}" }
    let(:endpoint) { api_host + path }

    it 'makes a post request to the correct endpoint' do
      stub_request(:post, endpoint).to_return(status: 200)
      described_class.new.delete_school_data(school_id)
      expect(a_request(:post, endpoint)).to have_been_made
    end

    context 'when the response is successful,' do
      it 'returns true' do
        stub_request(:post, endpoint).to_return(status: 200)
        expect(described_class.new.delete_school_data(school_id)).to eq(true)
      end
    end

    context 'when the response has an error status,' do
      it 'sends the error and request details to VHLMonitor' do
        stub_request(:post, endpoint).to_return(
          status: 401,
          body: 'Not authorized'
        )
        described_class.new.delete_school_data(school_id)
        expect(VHLMonitor).to(
          have_received(:error).with(
            response: hash_including(
              response_body: 'Not authorized',
              status: 401
            ),
            request: {
              path: path,
              verb: :post
            }
          )
        )
      end
    end

    context 'when the request raises an exception,' do
      it 'sends the exception and request details to VHLMonitor' do
        error = StandardError.new('some network problem')
        stub_request(:post, endpoint).to_raise(error)
        described_class.new.delete_school_data(school_id)
        expect(VHLMonitor).to(
          have_received(:notify).with(
            error,
            request: {
              path: path,
              verb: :post
            }
          )
        )
      end
    end
  end

  describe '#delete_virtual_chat_recordings' do
    let(:path) { '/m3/delete_virtual_chat_recordings' }
    let(:endpoint) { api_host + path }
    let(:audio_paths) { ['foo.wav', 'bar.wav'] }

    def do_request
      described_class.new.delete_virtual_chat_recordings(audio_paths)
    end

    it 'makes a post request to the correct endpoint, passing the ' \
       'specified audio file paths' do
      stub_request(:post, endpoint).to_return(status: 200)

      do_request

      expect(
        a_request(:post, endpoint).with(body: { audio_paths: })
      ).to have_been_made
    end

    context 'when the response is successful,' do
      it 'returns true' do
        stub_request(:post, endpoint).to_return(status: 200)

        expect(do_request).to be(true)
      end
    end

    context 'when the response has an error status,' do
      it 'sends the error and request details to VHLMonitor' do
        stub_request(:post, endpoint).to_return(
          status: 401,
          body: 'Not authorized'
        )

        do_request

        expect(VHLMonitor).to have_received(:error).with(
          response: hash_including(
            response_body: 'Not authorized',
            status: 401
          ),
          request: {
            body: { audio_paths: },
            path:,
            verb: :post
          }
        )
      end
    end

    context 'when the request raises an exception,' do
      it 'sends the exception and request details to VHLMonitor' do
        error = StandardError.new('some network problem')
        stub_request(:post, endpoint).to_raise(error)

        do_request

        expect(VHLMonitor).to have_received(:notify).with(
          error,
          request: {
            body: { audio_paths: },
            path:,
            verb: :post
          }
        )
      end
    end
  end

  describe '#transfer_student_work' do
    let(:user_id) { 123 }
    let(:path) { "/m3/student_work_transfer/#{user_id}" }
    let(:endpoint) { api_host + path }
    let(:old_section) { create(:section) }
    let(:new_section) { create(:section) }

    def do_request
      described_class.new.transfer_student_work(user_id, old_section, new_section)
    end

    it 'makes a post request to the correct endpoint' do
      stub_request(:post, endpoint).to_return(status: 200)

      do_request

      expect(
        a_request(:post, endpoint).with(
          body: {
            new_section_guid: new_section.guid,
            old_section_guid: old_section.guid
          }
        )
      ).to have_been_made
    end

    context 'when the response is successful,' do
      it 'returns true' do
        stub_request(:post, endpoint).to_return(status: 200)

        expect(do_request).to eq(true)
      end
    end

    context 'when the response has an error status,' do
      it 'sends the error and request details to VHLMonitor' do
        stub_request(:post, endpoint).to_return(
          status: 401,
          body: 'Not authorized'
        )

        do_request

        expect(VHLMonitor).to have_received(:error).with(
          response: hash_including(
            response_body: 'Not authorized',
            status: 401
          ),
          request: {
            body: {
              new_section_guid: new_section.guid,
              old_section_guid: old_section.guid
            },
            path:,
            verb: :post
          }
        )
      end
    end

    context 'when the request raises an exception,' do
      it 'sends the exception and request details to VHLMonitor' do
        error = StandardError.new('some network problem')
        stub_request(:post, endpoint).to_raise(error)

        do_request

        expect(VHLMonitor).to have_received(:notify).with(
          error,
          request: {
            body: {
              new_section_guid: new_section.guid,
              old_section_guid: old_section.guid
            },
            path:,
            verb: :post
          }
        )
      end
    end
  end
end
