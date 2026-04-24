describe StatsProcessor do
  let(:stats_test) { StatsTest.new }
  let(:payload) { { foo: 'bar' } }

  before do
    allow(STATS_PROXY).to receive(:info)
    allow(STATS_PROXY).to receive(:error)
  end

  describe '#dispatch' do
    it 'has required params' do
      expect do
        stats_test.dispatch
      end.to raise_error(ArgumentError, 'missing keywords: :payload, :stats_index')
    end

    it 'sends required data' do
      stats_test.dispatch(payload: payload, stats_index: 'my_index')
      expect(STATS_PROXY).to have_received(:info)
        .with(hash_including(vhl_component: 'my_index',
                             application: :m3,
                             environment: Rails.env))
    end

    it "sends an optional 'type' value" do
      stats_test.dispatch(payload: payload, stats_index: 'my_index', stats_type: 'my_type')
      expect(STATS_PROXY).to have_received(:info)
        .with(hash_including('type' => 'my_type'))
    end

    it "does not set 'type' if not provided" do
      stats_test.dispatch(payload: payload, stats_index: 'my_index', stats_type: nil)
      expect(STATS_PROXY).to have_received(:info)
        .with(hash_excluding('type' => nil))
    end

    it 'includes error information when provided' do
      my_error = StandardError.new('my error')
      allow(my_error).to receive(:backtrace).and_return(['error location'])

      stats_test.dispatch(payload: payload, stats_index: 'my_index', error: my_error)
      expect(STATS_PROXY).to have_received(:error)
        .with(hash_including(error_class: 'StandardError',
                             error_message: 'my error',
                             error_location: 'error location'))
    end
  end

  class StatsTest
    include StatsProcessor
  end
end
