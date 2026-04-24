describe BasePublishProcessor do
  class BasePublishTestModel; end
  class BasePublishTestError < RuntimeError; end

  class BasePublishProcessorTestClass
    include BasePublishProcessor

    VALID_ATTRIBUTES = [:id, :program_id]

    REQUIRED_ATTRIBUTES = [:id, :program_id]

    def initialize(params)
      super(published_model = BasePublishTestModel, params)
    end
  end

  let(:published_object) { double('BasePublishingModel', :errors => []) }
  let(:valid_params) { { 'id' => 1, 'program_id' => 1, 'name' => 'Test object' } }

  before do
    allow(BasePublishTestModel).to receive(:new).and_return(published_object)
    allow(BasePublishTestModel).to receive(:find_by_id).and_return(published_object)
    allow(published_object).to receive(:save)
    allow(published_object).to receive(:update)
    allow(published_object).to receive(:id=).with(1).and_return(1)
  end

  it 'exposes a request attribute that contains the params specified when initialized' do
    expected_params = { 'key' => 'value' }
    new_processor = BasePublishProcessorTestClass.new(expected_params)
    expect(new_processor.request).to eq(expected_params)
  end

  describe '#process_request' do

    context "when one of the required params is missing from the specified params" do
      it "sets an error referencing the missing param and does not try to do any update" do
        faulty_params = valid_params.dup
        faulty_params.delete('program_id')
        expect(BasePublishTestModel).not_to receive(:update)

        new_processor = BasePublishProcessorTestClass.new(faulty_params)
        new_processor.process_request
        expect(new_processor.errors.first).to match /^Data field 'program_id' for #{BasePublishTestModel} cannot be blank/
      end
    end

    context 'when there is no existing object with the specified id' do
      before do
        allow(BasePublishTestModel).to receive(:find_by_id).and_return(nil)
      end

      it 'creates a new publishable object based on request params' do
        expect(BasePublishTestModel).to receive(:new).with(hash_including('program_id' => 1)).and_return(published_object)
        new_processor = BasePublishProcessorTestClass.new(valid_params)
        new_processor.process_request
      end

      it 'assigns id to new publishable object when id param has been passed' do
        expect(published_object).to receive(:id=).with(1)
        new_processor = BasePublishProcessorTestClass.new(valid_params)
        new_processor.process_request
      end

      it 'creates a new publishable object using the correct params' do
        expect(BasePublishTestModel).not_to receive(:new).with(hash_including('some_param' => 'foo'))
        expect(BasePublishTestModel).to receive(:new).with(hash_including('program_id' => 1))
        new_processor = BasePublishProcessorTestClass.new(valid_params.merge('invalid_param' => 'foo'))
        new_processor.process_request
      end
    end

    context 'when there is an existing object with the specified id' do
      it 'updates a publishable object using request params' do
        expect(published_object).to receive(:update).with(hash_including('program_id' => 1))
        new_processor = BasePublishProcessorTestClass.new(valid_params)
        new_processor.process_request
      end

      it 'updates a publishable object using the correct params' do
        expect(published_object).not_to receive(:update).with(hash_including('some_param' => 'foo'))
        expect(published_object).to receive(:update).with(hash_including('program_id' => 1))
        new_processor = BasePublishProcessorTestClass.new(valid_params)
        new_processor.process_request
      end
    end

    it 'holds error messages when created/updated publishable object has errors' do
      error_array = ['Some new error']
      allow(error_array).to receive(:full_messages).and_return(error_array)
      allow(published_object).to receive(:errors).and_return(error_array)
      new_processor = BasePublishProcessorTestClass.new(valid_params)
      new_processor.process_request
      expect(new_processor.errors).to include 'Some new error'
    end

    it 'sets status attribute to :ok when no errors are raised' do
      new_processor = BasePublishProcessorTestClass.new(valid_params)
      new_processor.process_request
      expect(new_processor.status).to eq(:ok)
    end

    context 'when errors are raised' do
      let(:expected_error) { BasePublishTestError.new('some error') }

      before do
        allow(BasePublishTestModel).to receive(:find_by_id).and_raise expected_error
      end

      it 'notifies Rollbar of any problems' do
        expect(VHLMonitor).to receive(:notify).with(expected_error)
        new_processor = BasePublishProcessorTestClass.new(valid_params)
        new_processor.process_request
      end

      it 'sets errors attribute with raised errors message' do
        new_processor = BasePublishProcessorTestClass.new(valid_params)
        new_processor.process_request
        expect(new_processor.errors).to include expected_error.message
      end
    end
  end

  describe '#message' do
    context 'when there is no existing object with the specified id' do
      it 'sets the action to :create' do
        allow(BasePublishTestModel).to receive(:find_by_id).and_return(nil)
        new_processor = BasePublishProcessorTestClass.new(valid_params)
        new_processor.process_request
        expect(new_processor.message['action']).to eq('create')
      end
    end

    context 'when there is an existing object with the specified id' do
      it 'sets the action to :update' do
        new_processor = BasePublishProcessorTestClass.new(valid_params)
        new_processor.process_request
        expect(new_processor.message['action']).to eq('update')
      end
    end

    context 'when errors are raised' do
      let(:new_processor) { BasePublishProcessorTestClass.new(valid_params) }
      let(:expected_error) { BasePublishTestError.new('some error') }

      before do
        allow(BasePublishTestModel).to receive(:find_by_id).and_raise expected_error
      end

      it 'sets message text to errors when process had errors' do
        new_processor.process_request
        expect(new_processor.message['message_text']).to eq(expected_error.message)
      end

      it 'sets backtrace key in message hash' do
        new_processor.process_request
        expect(new_processor.message['backtrace']).to eq(expected_error.backtrace)
      end
    end
  end
end
