describe DynamoWrapper do
  let(:client) { instance_double(Aws::DynamoDB::Client, delete_item: nil) }
  let(:table) { 'table' }
  let(:primary_key) { 'primary_key' }
  let(:data_loggers) { [ 'first_logger', 'second_logger' ] }
  let(:wrapper) { described_class.new(table: table, loggers: data_loggers) }
  let(:mock_latency_logger) { DynamoWrapper::LatencyLogger.new(data_loggers) }

  before do
    allow(DynamoWrapper::LatencyLogger).to receive(:new).and_return(mock_latency_logger)
    allow(mock_latency_logger).to receive(:with_query_logging).and_call_original
    allow(Aws::DynamoDB::Client).to receive(:new).and_return(client)
    allow(mock_latency_logger).to receive(:log)
  end

  describe '#client' do
    let(:region) { 'aws region' }
    let(:profile_name) { 'aws profile' }

    context 'when no region is passed to the wrapper,' do
      let(:wrapper) do
        described_class.new(
          table: table
        )
      end

      it 'instantiates a dynamodb client with the region defined in the Rails configuration' do
        wrapper.client
        expect(Aws::DynamoDB::Client).to have_received(:new).with(
          region: DynamoConfig.region
        )
      end
    end

    context 'when a region is passed to the wrapper,' do
      let(:wrapper) do
        described_class.new(
          table: table,
          region: region
        )
      end

      it 'instantiates a dynamodb client with the given region' do
        wrapper.client
        expect(Aws::DynamoDB::Client).to have_received(:new).with(
          region: region
        )
      end
    end

    context 'when a profile is passed to the wrapper,' do
      let(:wrapper) do
        described_class.new(
          table: table,
          region: region,
          profile: profile_name
        )
      end
      let(:shared_credentials) { instance_double(Aws::SharedCredentials) }

      before do
        allow(Aws::SharedCredentials).to receive(:new)
          .with(profile_name: profile_name).and_return(shared_credentials)
      end

      it 'instantiates a dynamodb client with the credentials for the given profile' do
        wrapper.client
        expect(Aws::DynamoDB::Client).to have_received(:new).with(
          region: region,
          credentials: shared_credentials
        )
      end
    end
  end

  describe '#find' do
    let(:selected_attributes) { ['attr_1', 'attr_2'] }
    let(:request) do
      {
        request_items: {
          table => {
            keys: primary_key,
            attributes_to_get: selected_attributes
          }
        }
      }
    end
    let(:responses) do
      [
        { 'attr_1' => 'value_1', 'attr_2' => 'value_2' }
      ]
    end
    let(:result) do
      instance_double(
        Aws::DynamoDB::Types::BatchGetItemOutput,
        responses: { table => responses }
      )
    end

    before do
      allow(client).to receive(:batch_get_item).with(request).and_return(result)
    end

    def find_items
      wrapper.find(
        primary_key: primary_key,
        selected_attributes: selected_attributes
      )
    end

    it 'returns the items found' do
      expect(find_items).to eq(responses)
    end

    it 'instantiates the latency logger' do
      find_items
      expect(DynamoWrapper::LatencyLogger)
        .to have_received(:new)
        .with(data_loggers)
    end

    it 'calls the latency logger with the correct args' do
      find_items
      expect(mock_latency_logger)
        .to have_received(:with_query_logging)
        .with(metric: :find_query, info: { primary_key: primary_key })
    end
  end

  describe '#put' do
    let(:new_item) { { 'AlbumTitle' => { s: 'Somewhat Famous' } } }
    let(:request) do
      {
        item: new_item,
        table_name: table
      }
    end
    let(:result) do
      instance_double(
        Aws::DynamoDB::Types::PutItemOutput
      )
    end

    before do
      allow(client).to receive(:put_item).with(request).and_return(result)
    end

    def put_item
      wrapper.put(new_item: new_item)
    end

    it 'creates a new item, or replaces an old item with a new item' do
      put_item
      expect(client).to have_received(:put_item)
    end

    it 'instantiates the latency logger' do
      put_item
      expect(DynamoWrapper::LatencyLogger)
        .to have_received(:new)
        .with(data_loggers)
    end

    it 'calls the latency logger with the correct args' do
      put_item
      expect(mock_latency_logger)
        .to have_received(:with_query_logging)
        .with(metric: :put_query, info: { item: new_item })
    end
  end

  describe '#update' do
    let(:item_updates) do
      {
        'AlbumTitle': 'Louder Then Ever',
        year: '2018'
      }
    end
    let(:attribute_names) do
      item_updates.each_with_object({}) do |(name, _value), memo|
        memo["##{name}"] = name
      end
    end
    let(:attribute_values) do
      item_updates.each_with_object({}) do |(name, value), memo|
        memo[":#{name}"] = value
      end
    end
    let(:update_query) do
      'SET ' + item_updates.keys.map { |name| "##{name} = :#{name}" }.join(', ')
    end
    let(:request) do
      {
        key: primary_key,
        table_name: table,
        expression_attribute_names: attribute_names,
        expression_attribute_values: attribute_values,
        update_expression: update_query
      }
    end
    let(:result) do
      instance_double(
        Aws::DynamoDB::Types::UpdateItemOutput
      )
    end

    before do
      allow(client).to receive(:update_item).with(request).and_return(result)
    end

    def update_item
      wrapper.update(primary_key: primary_key, item_updates: item_updates)
    end

    it "updates an existing item's attributes" do
      update_item
      expect(client).to have_received(:update_item)
    end

    it 'instantiates the latency logger' do
      update_item
      expect(DynamoWrapper::LatencyLogger)
        .to have_received(:new)
        .with(data_loggers)
    end

    it 'calls the latency logger with the correct args' do
      update_item
      expect(mock_latency_logger)
        .to have_received(:with_query_logging)
        .with(metric: :update_query, info: { primary_key: primary_key })
    end
  end

  describe '#delete_item' do
    let(:key_to_delete) { SecureRandom.uuid }

    it 'deletes an item by primary_key' do
      wrapper.delete_item(primary_key: key_to_delete)
      expect(client).to have_received(:delete_item).with(
        key: key_to_delete,
        table_name: table
      )
    end

    it 'instantiates the latency logger' do
      wrapper.delete_item(primary_key: key_to_delete)
      expect(DynamoWrapper::LatencyLogger)
        .to have_received(:new)
        .with(data_loggers)
    end

    it 'calls the latency logger with the correct args' do
      wrapper.delete_item(primary_key: key_to_delete)
      expect(mock_latency_logger)
        .to have_received(:with_query_logging)
        .with(metric: :delete_query, info: { primary_key: key_to_delete })
    end
  end
end

describe DynamoWrapper::LatencyLogger do
  let(:logger) { double('FakeLogger') }
  let(:latency_logger) { described_class.new([logger]) }
  let(:query_name) { 'query name' }
  let(:query_info) { 'some info' }
  let(:query_latency) { 1234 }
  let(:query_result) { { 'some' => 'result' } }
  let(:query_error) { StandardError.new('some error') }

  before do
    allow(latency_logger).to receive(:time_event).and_call_original
    allow(latency_logger).to receive(:response_time).and_return(
      query_name => query_latency
    )
    allow(latency_logger).to receive(:log).and_call_original
    allow(logger).to receive(:log)
  end

  describe '#errors?' do
    it 'returns false when there is no error' do
      expect(latency_logger.errors?).to be(false)
    end

    it 'returns true when there is some error' do
      latency_logger.errors << query_error
      expect(latency_logger.errors?).to be(true)
    end
  end

  describe '@error_messages' do
    let(:errors) do
      [
        StandardError.new('some error 1'),
        StandardError.new('some error 2')
      ]
    end

    it 'returns an array of all the error messages' do
      latency_logger.errors.push(*errors)
      expect(latency_logger.error_messages).to eq(errors.map(&:message))
    end
  end

  describe '#with_query_logging' do
    def with_query_logging
      latency_logger.with_query_logging(
        metric: query_name, info: query_info
      ) do
        query_result
      end
    end

    it 'records timing information' do
      with_query_logging
      expect(latency_logger).to have_received(:time_event).with(query_name)
    end

    it 'logs the data' do
      with_query_logging
      expect(latency_logger).to have_received(:log).with(
        metric: query_name, info: query_info
      )
    end

    context 'when the called block raises an exception,' do
      def with_query_logging
        latency_logger.with_query_logging(
          metric: query_name, info: query_info
        ) do
          raise query_error
        end
      end

      it 'does not re-raise the exception' do
        expect { with_query_logging }.not_to raise_error
      end

      it 'saves the exception message' do
        with_query_logging
        expect(latency_logger.errors).to eq([query_error])
      end

      it 'records timing information' do
        with_query_logging
        expect(latency_logger).to have_received(:time_event).with(query_name)
      end

      it 'logs the data' do
        with_query_logging
        expect(latency_logger).to have_received(:log).with(
          metric: query_name, info: query_info, error: query_error
        )
      end
    end
  end

  describe '#log' do
    let(:metric) { query_name }
    let(:info) { 'some info' }
    let(:error) { 'some error' }

    it 'call the loggers' do
      latency_logger.log(metric: metric, info: info, error: error)
      expect(logger).to have_received(:log).with(
        latency: query_latency,
        metric: metric,
        info: info,
        error: error
      )
    end
  end
end

describe DynamoWrapper::LogStashLogger do
  let(:stats_index) { 'some stats index' }
  let(:dynamo_table) { 'some_table' }
  let(:logger) { described_class.new(stats_index: stats_index, dynamo_table: dynamo_table) }

  describe '#log' do
    let(:metric) { 'some_metric' }
    let(:latency) { 1234 }
    let(:info) { 'some_info' }
    let(:error) { 'some error' }

    before do
      allow(logger).to receive(:dispatch)
    end

    it 'logs info to logstash' do
      logger.log(latency: latency, metric: metric, info: info, error: error)
      expect(logger).to have_received(:dispatch).with(
        payload: {
          dynamo_table: dynamo_table,
          service: 'dynamodb',
          latency: { duration: latency },
          additional_info: info
        },
        stats_index: stats_index,
        stats_type: "#{metric}_latency",
        error: error
      )
    end
  end
end

describe DynamoWrapper::DatadogLogger do
  let(:logger) { described_class.new }

  describe '#log' do
    let(:metric) { 'some_metric' }
    let(:latency) { 1234 }
    let(:info) { 'some_info' }
    let(:error) { 'some error' }

    before do
      allow(logger).to receive(:ddog_dispatch)
    end

    it 'logs info to datadog' do
      logger.log(latency: latency, metric: metric, info: info, error: error)
      expect(logger).to have_received(:ddog_dispatch).with(
        metric: "m3.dynamo.#{metric}.latency",
        stats_type: :gauge,
        role: 'dynamo',
        value: latency
      )
    end
  end
end
