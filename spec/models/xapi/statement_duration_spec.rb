describe Xapi::StatementDuration do
  around do |example|
    Timecop.freeze(Time.new(2018, 12, 25, 17, 0, 0)) do
      example.run
    end
  end

  def create_statement(timestamp:, verb:)
    Xapi::Statement.new(
      id: SecureRandom.uuid,
      timestamp: timestamp,
      stored: timestamp,
      verb: verb
    )
  end

  def validate_duration(statements, expected_duration)
    expect(described_class.new(statements).duration).to eq(expected_duration)
  end

  describe '#duration' do
    context 'when there is only one statement' do
      context 'when the statement verb is "terminated"' do
        let(:statements) do
          [
            create_statement(timestamp: Time.now, verb: Xapi::VERB_TERMINATED)
          ]
        end

        it 'returns 0' do
          validate_duration(statements, 0)
        end
      end

      context 'when the statement verb is different than "terminated"' do
        it 'returns 0' do
          [
            Xapi::VERB_INITIALIZED,
            Xapi::VERB_EXPERIENCED,
            Xapi::VERB_ATTEMPTED,
            Xapi::VERB_TERMINATED
          ].each do |verb|
            statements = [create_statement(timestamp: Time.now, verb: verb)]
            validate_duration(statements, 0)
          end
        end
      end
    end

    context 'when there are no statement with the verb "terminated"' do
      let(:statements) do
        [
          create_statement(verb: Xapi::VERB_INITIALIZED, timestamp: 5.minutes.ago),
          create_statement(verb: Xapi::VERB_EXPERIENCED, timestamp: 3.minutes.ago),
          create_statement(verb: Xapi::VERB_ANSWERED, timestamp: Time.now)
        ]
      end

      it 'returns the time between the first statement and the last statement' do
        validate_duration(statements, 5 * 60)
      end
    end

    context 'when there are statements with the verb "terminated"' do
      let(:statements) do
        [
          create_statement(verb: Xapi::VERB_INITIALIZED, timestamp: 10.minutes.ago),
          create_statement(verb: Xapi::VERB_EXPERIENCED, timestamp: 8.minutes.ago),
          create_statement(verb: Xapi::VERB_TERMINATED, timestamp: 7.minutes.ago),
          create_statement(verb: Xapi::VERB_INITIALIZED, timestamp: 4.minutes.ago),
          create_statement(verb: Xapi::VERB_TERMINATED, timestamp: 3.minutes.ago),
          create_statement(verb: Xapi::VERB_INITIALIZED, timestamp: 1.minutes.ago),
          create_statement(verb: Xapi::VERB_ANSWERED, timestamp: Time.now)
        ]
      end

      it 'returns the sum of all the sessions' do
        validate_duration(statements, 3 * 60 + 1 * 60 + 1 * 60)
      end
    end

    context 'when there are sessions with missing "terminated" verbs' do
      let(:statements) do
        [
          create_statement(verb: Xapi::VERB_INITIALIZED, timestamp: 10.minutes.ago),
          create_statement(verb: Xapi::VERB_EXPERIENCED, timestamp: 8.minutes.ago),
          create_statement(verb: Xapi::VERB_INITIALIZED, timestamp: 4.minutes.ago),
          create_statement(verb: Xapi::VERB_TERMINATED, timestamp: 3.minutes.ago),
          create_statement(verb: Xapi::VERB_INITIALIZED, timestamp: 1.minutes.ago),
          create_statement(verb: Xapi::VERB_ANSWERED, timestamp: Time.now)
        ]
      end

      it 'returns the sum of all the sessions' do
        validate_duration(statements, 2 * 60 + 1 * 60 + 1 * 60)
      end
    end

    context 'when there are sessions with missing "initialized" verbs' do
      let(:statements) do
        [
          create_statement(verb: Xapi::VERB_INITIALIZED, timestamp: 10.minutes.ago),
          create_statement(verb: Xapi::VERB_EXPERIENCED, timestamp: 8.minutes.ago),
          create_statement(verb: Xapi::VERB_INITIALIZED, timestamp: 4.minutes.ago),
          create_statement(verb: Xapi::VERB_TERMINATED, timestamp: 3.minutes.ago),
          create_statement(verb: Xapi::VERB_ANSWERED, timestamp: Time.now)
        ]
      end

      it 'returns the sum of all the sessions' do
        validate_duration(statements, 2 * 60 + 1 * 60 + 0 * 60)
      end
    end
  end
end
