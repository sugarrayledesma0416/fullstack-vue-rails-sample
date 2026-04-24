describe Sidekiq::Middleware::Server::Logstash do
  let(:logstash) { double('LogstashClient') }
  let(:logstash_middleware) do
    Sidekiq::Middleware::Server::Logstash.new(client: logstash)
  end

  describe '#call' do
    context "when job completes normally" do
      let(:test_worker) { LogstashMiddlewareTestWorker.new }

      it 'sends data to the logstash client', test_debt: true do
        expect(logstash).to receive(:info)
          .with(
            hash_including(
              application: 'M3',
              duration: anything,
              environment: 'test',
              retry_count: 0,
              start_time: anything,
              vhl_component: 'sidekiq',
              worker_class: "LogstashMiddlewareTestWorker"
            )
          )
        logstash_middleware.call(test_worker, { jid: '1' }, nil) do
          test_worker.perform(123, 'my name')
        end
      end
    end

    context "when the job errors" do
      let(:error_worker) { LogstashMiddlewareErrorWorker.new }

      it "logs error information and raises the error" do
        expect(logstash).to receive(:error)
          .with(
            hash_including(
              error_class: 'RuntimeError',
              error_message: 'Fatal error test',
              error_location: anything
            )
          )
        expect do
          logstash_middleware.call(error_worker, { jid: '1' }, nil) do
            error_worker.perform(123, 'my name')
          end
        end.to raise_error(RuntimeError, 'Fatal error test')
      end
    end
  end

  class LogstashMiddlewareTestWorker
    include Sidekiq::Worker
    include WorkerInstrumentation

    sidekiq_options retry: false

    def perform(id, name)
      logger_data_merge(id: id, name: name)
      [id, name]
    end
  end

  class LogstashMiddlewareErrorWorker < LogstashMiddlewareTestWorker
    def perform(id, name)
      logger_data_merge(id: id, name: name)
      raise "Fatal error test"
    end
  end

end
