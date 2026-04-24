describe Xapi::Statement, if: DynamoConfig.use_local?,
                          use_local_dynamodb: true do
  around do |example|
    # The statement writer adds timestamp when not provided by the Learning
    # Record Provider. So we wrap all the examples with Timecop to be able to
    # check the timestamp creation and validity.
    # We also need to freeze the time to a time with no micro seconds because
    # during the serialization of instances of 'Time' we can lose some precision.
    # TODO: not sure this is really needed for these tests
    Timecop.freeze(Time.new(2018, 12, 25, 17, 0, 0)) do
      example.run
    end
  end

  let(:learning_module_id) { 'https://netexlearning.com/487203' }
  let(:object_type) { Xapi::Statement::OBJECT_TYPE_ACTIVITY }
  let(:new_statement_timestamp) { Time.now.utc }
  let(:attempt) { build_stubbed(:attempt) }
  let(:statement_1) { create_statement }

  def create_statement(attrs = {})
    params = {
      id: SecureRandom.uuid,
      timestamp: new_statement_timestamp,
      verb: Xapi::VERB_ANSWERED,
      result: {},
      object: { objectType: object_type, id: learning_module_id },
      stored: Time.now.utc
    }.merge(attrs)
    Xapi::Statement.new(params)
  end

  def all_stored_statements
    described_class.scan.to_a
  end

  describe '.store' do
    before do
      allow(VHLMonitor).to receive(:warning)
    end

    context 'when no statement with the same id exists,' do
      let(:statement_2) { create_statement }

      it 'successfully stores the new statement' do
        statement_1.store(attempt)
        statement_2.store(attempt)
        expect(all_stored_statements).to include(statement_1, statement_2)
      end

      it 'returns true' do
        statement_1.store(attempt)
        expect(statement_2.store(attempt)).to be true
      end

      it 'does not send a warning to the VHLMonitor' do
        statement_1.store(attempt)
        statement_2.store(attempt)
        expect(VHLMonitor).not_to have_received(:warning)
      end
    end

    context 'when a statement with the same id and with the same content already exists' do
      let(:statement_2) { create_statement(id: statement_1.id) }

      it 'does not store the statement' do
        statement_1.store(attempt)
        expect(all_stored_statements.size).to eq(2)
        statement_2.store(attempt)
        expect(all_stored_statements.size).to eq(2)
      end

      it 'returns false' do
        statement_1.store(attempt)
        expect(statement_2.store(attempt)).to be false
      end

      it 'does not send a warning to the VHLMonitor' do
        statement_1.store(attempt)
        statement_2.store(attempt)
        expect(VHLMonitor).not_to have_received(:warning)
      end
    end

    context 'when a statement with the same id and a conflicting content already exists' do
      # For the conflicting statement, we use the same statement with a different verb
      let(:statement_2) do
        create_statement(
          statement_1.attrs.merge(verb: Xapi::VERB_INITIALIZED)
        )
      end

      it 'does not store the statement' do
        statement_1.store(attempt)
        statement_2.store(attempt)
        expect(all_stored_statements).not_to include(statement_2)
      end

      it 'returns false' do
        statement_1.store(attempt)
        expect(statement_2.store(attempt)).to be false
      end

      it 'sends a warning to the VHLMonitor' do
        statement_1.store(attempt)
        statement_2.store(attempt)
        expect(VHLMonitor).to have_received(:warning)
      end
    end

    context 'when a statement with the same id and a non-conflicting content already exists' do
      # For the non conflicting statement, we change the timestamp that should be ignored
      let(:statement_2) do
        create_statement(
          statement_1.attrs.merge(timestamp: statement_1.timestamp + 1.hour)
        )
      end

      it 'does not store the statement' do
        statement_1.store(attempt)
        statement_2.store(attempt)
        expect(all_stored_statements).not_to include(statement_2)
      end

      it 'returns false' do
        statement_1.store(attempt)
        expect(statement_2.store(attempt)).to be false
      end

      it 'does not send a warning to the VHLMonitor' do
        statement_1.store(attempt)
        statement_2.store(attempt)
        expect(VHLMonitor).not_to have_received(:warning)
      end
    end

    it 'saves the statement preserving the empty and nil attributes' do
      statement = create_statement(
        empty_str: '',
        empty_array: [],
        empty_hash: {},
        array_with_empty_string: ['hello', '', 'world'],
        array_with_nil_element: ['hello', nil, 'world'],
        hash_with_empty_string_value: { key: '' },
        hash_with_nil_value: { key: nil }
      )
      statement.store(attempt)
      stored_statement = described_class.query_by_statement_id(statement.id)
      expect(stored_statement.attrs[:empty_str]).to eq('')
      expect(stored_statement.attrs[:empty_array]).to eq([])
      expect(stored_statement.attrs[:empty_hash]).to eq({})
      expect(stored_statement.attrs[:array_with_empty_string]).to eq(['hello', '', 'world'])
      expect(stored_statement.attrs[:array_with_nil_element]).to eq(['hello', nil, 'world'])
      expect(stored_statement.attrs[:hash_with_empty_string_value][:key]).to eq('')
      expect(stored_statement.attrs[:hash_with_nil_value][:key]).to eq(nil)
    end
  end

  describe '.query_by_attempt' do
    let(:statement_1) { create_statement }
    let(:statement_2) { create_statement }
    let(:statement_3) { create_statement }
    let(:statement_4) { create_statement }
    let(:statement_5) { create_statement }
    let(:statement_6) { create_statement }

    it 'only returns the statement from the attempt' do
      other_attempt = build_stubbed(:attempt)
      [statement_1, statement_2, statement_6].each do |statement|
        statement.store(attempt)
      end
      [statement_3, statement_4, statement_5].each do |statement|
        statement.store(other_attempt)
      end
      expect(described_class.query_by_attempt(attempt)).to match_array(
        [statement_1, statement_2, statement_6]
      )
      expect(described_class.query_by_attempt(other_attempt)).to match_array(
        [statement_3, statement_4, statement_5]
      )
    end
  end

  describe '.query_by_statement_id' do
    let(:statement_1) { create_statement }
    let(:statement_2) { create_statement }
    let(:statement_3) { create_statement }

    before do
      statement_1.store(attempt)
      statement_2.store(attempt)
      statement_3.store(attempt)
    end

    it 'returns the statement when a statement with the specified id exists' do
      expect(described_class.query_by_statement_id(statement_2.id)).to eq(statement_2)
    end

    it 'returns nil when no statement with the specified id exists' do
      expect(described_class.query_by_statement_id('non existing id')).to be_nil
    end
  end

  describe '.query_for_answered' do
    let(:statement_1) { create_statement(timestamp: 8.minutes.ago.utc) }
    let(:statement_2) { create_statement(verb: Xapi::VERB_INITIALIZED) }
    let(:statement_3) { create_statement(timestamp: Time.now.utc) }
    let(:statement_4) { create_statement(verb: Xapi::VERB_EXPERIENCED) }
    let(:statement_5) { create_statement(verb: Xapi::VERB_ATTEMPTED) }
    let(:statement_6) { create_statement(timestamp: 1.minute.ago.utc) }

    it 'returns all the statements with the answered verb' do
      [statement_1, statement_2, statement_3, statement_4, statement_5, statement_6].each do |statement|
        statement.store(attempt)
      end
      expect(described_class.query_for_answered(attempt)).to match_array(
        [statement_1, statement_3, statement_6]
      )
    end

    it 'only returns the statement with the answered verb from the attempt' do
      other_attempt = build_stubbed(:attempt)
      [statement_1, statement_2, statement_6].each do |statement|
        statement.store(attempt)
      end
      [statement_3, statement_4, statement_5].each do |statement|
        statement.store(other_attempt)
      end
      expect(described_class.query_for_answered(attempt)).to match_array(
        [statement_1, statement_6]
      )
    end
  end

  describe '.query_for_answered_count' do
    let(:statement_1) { create_statement(timestamp: 8.minutes.ago.utc) }
    let(:statement_2) { create_statement(verb: Xapi::VERB_INITIALIZED) }
    let(:statement_3) { create_statement(timestamp: Time.now.utc) }
    let(:statement_4) { create_statement(verb: Xapi::VERB_EXPERIENCED) }
    let(:statement_5) { create_statement(verb: Xapi::VERB_ATTEMPTED) }
    let(:statement_6) { create_statement(timestamp: 1.minute.ago.utc) }

    it 'returns the number of statements with the answered verb' do
      [statement_1, statement_2, statement_3, statement_4, statement_5, statement_6].each do |statement|
        statement.store(attempt)
      end
      expect(described_class.query_for_answered_count(attempt)).to eq(3)
    end

    it 'only returns the number of statements with the answered verb from the attempt' do
      other_attempt = build_stubbed(:attempt)
      [statement_1, statement_2, statement_6].each do |statement|
        statement.store(attempt)
      end
      [statement_3, statement_4, statement_5].each do |statement|
        statement.store(other_attempt)
      end
      expect(described_class.query_for_answered_count(attempt)).to eq(2)
    end

    it 'correctly handles dynamodb pagination' do
      [statement_1, statement_2, statement_3, statement_4, statement_5, statement_6].each do |statement|
        statement.store(attempt)
      end
      expect(described_class.query_for_answered_count(attempt, limit: 2)).to eq(3)
    end
  end

  describe '.query_for_duration' do
    let(:statement_1) { create_statement(timestamp: 8.minutes.ago.utc) }
    let(:statement_2) { create_statement(verb: Xapi::VERB_INITIALIZED) }
    let(:statement_3) { create_statement(timestamp: Time.now.utc) }
    let(:statement_4) { create_statement(verb: Xapi::VERB_EXPERIENCED) }
    let(:statement_5) { create_statement(verb: Xapi::VERB_ATTEMPTED) }
    let(:statement_6) { create_statement(timestamp: 1.minute.ago.utc) }

    def statements_relevant_attributes(statements)
      statements.map do |statement|
        statement.to_h.slice(:verb, :timestamp)
      end
    end

    it 'returns all the statements from the attempt with only the verb and timestamp attributes set' do
      [statement_1, statement_2, statement_5, statement_6].each do |statement|
        statement.store(attempt)
      end
      other_attempt = build_stubbed(:attempt)
      [statement_3, statement_4].each do |statement|
        statement.store(other_attempt)
      end
      # We only use the `verb` and `timestamp` attributes to compare the statements
      expect(
        statements_relevant_attributes(described_class.query_for_duration(attempt))
      ).to match_array(
        statements_relevant_attributes([statement_1, statement_2, statement_5, statement_6])
      )
    end
  end

  describe '.delete_statements_by_attempt' do
    let(:statement_1) { create_statement }
    let(:statement_2) { create_statement }
    let(:statement_3) { create_statement }
    let(:statement_4) { create_statement }
    let(:statement_5) { create_statement }
    let(:statement_6) { create_statement }

    it 'deletes all the statements for the attempt' do
      other_attempt = build_stubbed(:attempt)
      [statement_1, statement_2, statement_4, statement_6].each do |statement|
        statement.store(attempt)
      end
      [statement_3, statement_5].each do |statement|
        statement.store(other_attempt)
      end
      expect(described_class.query_by_attempt(attempt).count).to eq(4)
      expect(described_class.query_by_attempt(other_attempt).count).to eq(2)
      described_class.delete_statements_by_attempt(attempt)
      expect(described_class.query_by_attempt(attempt).count).to eq(0)
      expect(described_class.query_by_attempt(other_attempt).count).to eq(2)
      described_class.delete_statements_by_attempt(other_attempt)
      expect(described_class.query_by_attempt(attempt).count).to eq(0)
      expect(described_class.query_by_attempt(other_attempt).count).to eq(0)
    end
  end

  describe '#activity_id' do
    let(:statement_7) { create_statement }
    it 'returns the activity id' do
      expect(statement_7.activity_id).to eq('https://netexlearning.com/487203')
    end
  end
end
