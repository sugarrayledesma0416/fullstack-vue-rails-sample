describe TimingEvents do
  let(:stats_test) { TimingEventsTest.new }

  describe '#time_event' do
    it 'stores event timing in a hash with a default or provided key' do
      stats_test.time_event do
        sleep 0.01
      end
      expect(stats_test.response_time).to be_a Hash
      expect(stats_test.response_time.keys).to eq [:default]

      stats_test.time_event(:my_key) do
        sleep 0.01
      end
      expect(stats_test.response_time.keys).to eq [:default, :my_key]
    end

    it 'stores timing in milliseconds as an integer' do
      stats_test.timed_method
      expect(stats_test.response_time[:timer_test]).to be_an Integer
      # if this next test fails sporatically, either adjust within or remove the test
      expect(stats_test.response_time[:timer_test]).to be_within(5).of(100)
    end

    it 'stores timing even when there is an error' do
      stats_test.timed_method_with_error
      expect(stats_test.response_time[:error_test]).to be_an Integer
      # if this next test fails sporatically, either adjust within or remove the test
      expect(stats_test.response_time[:error_test]).to be_within(5).of(100)
    end
  end

  class TimingEventsTest
    include TimingEvents

    def timed_method
      time_event(:timer_test) do
        sleep 0.1
      end
    end

    def timed_method_with_error
      time_event(:error_test) do
        sleep 0.1
        raise StandardError.new('timing test on error')
      end
    rescue StandardError => e
      Rails.logger.debug('Test error: #{e.message}')
    end
  end
end
