require 'vhl_monitor'

module VHLMonitor
  describe LogstashNotifier do
    it 'logs errors when provided with undefined monitors' do
      expect(Rails.logger).to receive(:warn).with(/something/)
      expect(VHLMonitor).to receive(:notify)

      described_class.initialize(:something)
    end

    it 'is able to handle additional monitros' do
      new_monitors = { my_great_erorrs: { StandardError => [/.*/] },
                       my_not_so_great_errors: { ZeroDivisionError => [/do not devide by zero/] } }

      stub_const('VHLMonitor::MONITORS', new_monitors)

      described_class.initialize(:my_great_erorrs)

      expect(Rails.logger).not_to receive(:warn)
      expect(VHLMonitor).not_to receive(:notify)
    end

    context '#notify' do
      let(:fake_logstash) { double('Logstah') }
      let(:notifier) { described_class }

      before do
        notifier.initialize(:mysql_server_errors)
        allow(notifier).to receive(:logstash).and_return(fake_logstash)
      end

      it 'sends logstash notification when registred exception occures' do
        expect(fake_logstash).to receive(:error).with(
          hash_including(sub_category: 'ActiveRecord::ConnectionNotEstablished:(?-mix:.*)'))

        notifier.notify(ActiveRecord::ConnectionNotEstablished.new('nothing to see here'))
      end

      it 'does not send any notifications when not registred exception occures' do
        expect(fake_logstash).not_to receive(:error)
        notifier.notify(StandardError.new('oops I did it again'))
      end

      context 'when context variable passed' do
        let(:custom_context) { 'custom context' }

        it 'passes context to logstash' do
          expect(fake_logstash).to receive(:error).with(
            hash_including(context: custom_context))

          notifier.notify(ActiveRecord::ConnectionNotEstablished.new('error with context'),
                          custom_context)
        end
      end

      context 'when exception has a backtrace' do
        before do
          new_monitors = { basic_errors: { ZeroDivisionError => [/.*/] } }
          stub_const('VHLMonitor::MONITORS', new_monitors)
          described_class.initialize(:basic_errors)
        end

        it 'passes correctly encoded json with the backtrace' do
          begin
            1 / 0
          rescue => exception
            expect(fake_logstash).to receive(:error)
              .with(kind_of(Hash))
              .with(hash_including(backtrace: kind_of(String)))

            notifier.notify(exception)
          end
        end
      end
    end
  end
end
