describe VHLMonitor do
  describe '.notify' do
    let(:exception) { StandardError.new }
    let(:context) { { 'some_key' => 'some_value' } }

    before do
      allow(VHLMonitor::LogstashNotifier).to receive(:notify)
      if defined?(Rollbar)
        allow(Rollbar).to receive(:error)
      else
        Rollbar = double('Rollbar', error: nil)
      end
    end

    it 'sends the specified exception to LogstashNotifier' do
      expect(described_class::LogstashNotifier).to receive(:notify)
        .with(exception)

      described_class.notify(exception, context)
    end

    it 'sends the specified exception and context hash to Rollbar' do
      expect(Rollbar).to receive(:error).with(exception, context)

      described_class.notify(exception, context)
    end

    context 'with no context argument' do
      it 'sends the specified exception and an empty hash to Rollbar' do
        expect(Rollbar).to receive(:error).with(exception, {})

        described_class.notify(exception)
      end
    end

    context 'when context contains a rack_env key' do
      it 'excludes the rack_env key from the context sent to Rollbar' do
        bad_context = context.merge(rack_env: 'bad_env')

        expect(Rollbar).to receive(:error) do |exception_arg, context_arg|
          expect(exception_arg).to eq(exception)
          expect(context_arg).not_to have_key(:rack_env)
        end

        described_class.notify(exception, bad_context)
      end
    end
  end
end
