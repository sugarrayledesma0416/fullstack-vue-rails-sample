describe WorkerInstrumentation do
  let(:worker) { WorkerInstrumentationTestWorker.new }
  let(:id) { 123 }
  let(:name) { 'Matilda' }

  it "stores information in a hash" do
    worker.perform(id, name)
    expect(worker.logger_data).to be_a Hash
    expect(worker.logger_data[:id]).to eq id
    expect(worker.logger_data[:name]).to eq name
  end

  class WorkerInstrumentationTestWorker
    include Sidekiq::Worker
    include WorkerInstrumentation

    sidekiq_options retry: false

    def perform(id, name)
      logger_data_merge(id: id, name: name)
      [id, name]
    end
  end

  class WorkerInstrumentationErrorWorker < WorkerInstrumentationTestWorker

    def perform(id, name)
      logger_data_merge(id: id, name: name)
      raise "Fatal error test"
    end
  end
end
