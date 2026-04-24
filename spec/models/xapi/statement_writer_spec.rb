describe Xapi::StatementWriter, if: DynamoConfig.use_local?,
                                use_local_dynamodb: true do
  around do |example|
    # The statement writer adds timestamp when not provided by the Learning
    # Record Provider. So we wrap all the examples with Timecop to be able to
    # check the timestamp creation and validity.
    # We also need to freeze the time to a time with no micro seconds because
    # during the serialization of instances of 'Time' we can loose some precision.
    Timecop.freeze(Time.new(2018, 12, 25, 17, 0, 0)) do
      example.run
    end
  end

  let(:user) { create(:student) }
  let(:state_modifiable) { true }
  let(:user_token) do
    XapiUserToken.new(
      attempt_id: attempt.id,
      state_modifiable: state_modifiable,
      user_id: user.id
    )
  end
  let(:actor) { { objectType: 'Agent', mbox: user_token.mbox } }
  let(:page_location) { '#/lang/en/pag/2f6e65a01fe52899e7bc9ec3300d452c||en' }
  let(:learning_module_id) { 'https://netexlearning.com/487203' }
  let(:object_type) { Xapi::Statement::OBJECT_TYPE_ACTIVITY }
  let(:program) { create(:program) }
  let(:school) { create(:school) }
  let(:course) { create(:course, school: school) }
  let(:section) { create(:section, course: course) }
  let(:content_summary) do
    {
      'matching' => 2,
      'voice_recording' => 1
    }.to_json
  end
  let(:activity) do
    create(:activity, activity_type: 'smart_book', content_summary: content_summary)
  end
  let(:unknown_verb) { 'http://adlnet.gov/expapi/verbs/unknown' }
  let(:existing_statement) do
    create_statement(
      timestamp: 1.hour.ago.utc,
      verb: Xapi::VERB_ANSWERED
    )
  end
  let(:submission_mock) { instance_double(Gradebook::Submission) }
  let(:statement_duration_mock) { instance_double(Xapi::StatementDuration) }
  let(:responses_mock__) do
    # The statement writer calls the `answered` method to check if the number
    # of answered attempts changed before making a new submission.
    # In this spec we always saves one statement so we set `responses_mock.answered`
    # to an array of one element.
    instance_double(Smartbook::Responses, answered: ['answered response'], all_answered: ['answered response'])
  end
  let(:activity_time_spent) { 12_345 }
  let(:points_earned) { 42 }
  let(:score_calculator) do
    instance_double(Smartbook::ScoreCalculator, points_earned: points_earned)
  end
  let(:saved_response) { {} }
  let(:smartbook_recording_endpoint) { Rails.application.config.smartbook_recording_endpoint }

  def statement_writer(statement)
    params = statement.attrs.merge(
      actor: actor,
      verb: { id: statement.verb }
    )
    # convert the parameters to json and parse them back to get rid of typing
    # (such as Time, boolean, etc) to have arguments like we receive from the controller.
    described_class.new(JSON.parse(params.to_json, symbolize_names: true))
  end

  def create_statement(interaction_type: 'matching', **attrs)
    params = {
      id: SecureRandom.uuid,
      timestamp: Time.now.utc,
      verb: Xapi::VERB_ANSWERED,
      result: {},
      object: {
        objectType: object_type,
        id: learning_module_id,
        definition: { interactionType: interaction_type }
      },
      stored: Time.now.utc
    }.merge(attrs)
    Xapi::Statement.new(params)
  end

  def create_audio_recording_statement
    create_statement(
      interaction_type: 'other',
      result: {
        response: "#{smartbook_recording_endpoint}/#{section.guid}/lossless_token/blah"
      }
    )
  end

  # Returns the statement as it should be saved
  def saved_statement(statement)
    JSON.parse(statement.attrs.to_json, symbolize_names: true)
  end

  def attempt_stored_responses(attempt)
    attempt.reload
    attempt.uncache_smartbook_responses
    attempt.stored_responses
  end

  before do
    allow(Gradebook::Submission).to receive(:new).and_return(submission_mock)
    allow(submission_mock).to receive(:submit_points)
    allow(Xapi::StatementDuration).to receive(:new).and_return(statement_duration_mock)
    allow(statement_duration_mock).to receive(:duration).and_return(activity_time_spent)
    # allow(Smartbook::Response).to receive(:new).and_return(response_mock)
    # allow(response_mock).to receive(:instructor_gradable?).and_return(false)
    # allow(Smartbook::Responses).to receive(:new).and_return(responses_mock)
    # allow(Smartbook::Responses).to receive(:new) do |args|
    #   puts args.size
    #   (responses_mock)
    # end
    allow(Smartbook::ScoreCalculator).to receive(:new).and_return(score_calculator)
  end

  describe '#write' do
    context 'when no attempt exists,' do
      let(:attempt) { build_stubbed(:attempt) }
      let(:new_statement) { create_statement }

      it 'raises an error' do
        expect { statement_writer(new_statement).write }.to raise_error(ArgumentError)
      end
    end

    context 'when an attempt exists,' do
      let(:submission) do
        SubmissionClient::Submission.new('id' => 1, 'data' => saved_response)
      end
      let(:attempt_status) { AttemptStatus::CODE_SUBMITTED }
      let(:attempt) do
        create(
          :attempt,
          activity: activity,
          section: section,
          status_code: attempt_status,
          submission_id: submission.id,
          user: user
        )
      end

      before do
        allow(SubmissionClient::Submission).to receive(:create) do |attempt_id:, partition_key:, data:|
          # Save the data in json format
          submission.response['data'] = JSON.parse(data)
          submission
        end
        allow(SubmissionClient::Submission).to receive(:find)
          .with(attempt.submission_id, attempt.submission_partition_key)
          .and_return([submission])
      end

      context 'when no statement exists,' do
        let(:new_statement) { create_statement }

        it 'returns true' do
          expect(statement_writer(new_statement).write).to be_truthy
        end

        it 'saves the statement in the dynamodb table' do
          statement_writer(new_statement).write
          expect(Xapi::Statement.query_by_attempt(attempt)).to match_array(
            [new_statement]
          )
        end

        it 'saves the statement in the submission database if the verb is "answered"' do
          statement_writer(new_statement).write
          expect(SubmissionClient::Submission).to have_received(:create)
          expect(attempt_stored_responses(attempt)).to eq(
            'statements' => [new_statement.attrs]
          )
        end

        it 'does not save the statement in the submission database if the verb is not "answered"' do
          new_statement = create_statement(verb: Xapi::VERB_ATTEMPTED)
          statement_writer(new_statement).write
          expect(SubmissionClient::Submission).not_to have_received(:create)
        end

        # Return relevant attributes used to compare a statement passed to the
        # StatementDuration class.
        def statements_relevant_attributes(statements)
          statements.map do |statement|
            statement.to_h.slice(:verb, :timestamp)
          end
        end

        # we defined a custom matcher because we just want to check that the
        # statement passed to the duration calculator has the correct relevant
        # attributes.
        RSpec::Matchers.define :statements_for_duration_calculation do |expected_statements|
          match do |actual|
            statements_relevant_attributes(expected_statements) == statements_relevant_attributes(actual)
          end
        end

        it 'calculates the new attempt time spent' do
          statement_writer(new_statement).write
          attempt.reload
          expect(Xapi::StatementDuration).to have_received(:new).with(
            statements_for_duration_calculation([new_statement])
          )
          expect(statement_duration_mock).to have_received(:duration)
          expect(attempt.time_spent).to eq(activity_time_spent)
        end

        it 'calculates the new statement score' do
          statement_writer(new_statement).write
          expect(Smartbook::ScoreCalculator).to have_received(:new).with(attempt)
          expect(score_calculator).to have_received(:points_earned)
        end
      end

      context 'when statements already exist for this attempt,' do
        let(:existing_statements) { [existing_statement] }
        let(:new_statement) { create_statement }

        before do
          existing_statements.each do |statement|
            statement.store(attempt)
          end
        end

        context 'when the new statement conflicts with an existing statement,' do
          let(:new_statement) do
            create_statement(
              id: existing_statement.id,
              timetamp: existing_statement.timestamp + 1.hour
            )
          end

          it 'returns false' do
            expect(statement_writer(new_statement).write).to be_falsey
          end

          it 'does not save the statement in the dynamodb table' do
            statement_writer(new_statement).write
            expect(Xapi::Statement.query_by_attempt(attempt)).not_to include(
              new_statement
            )
          end
        end

        context 'when the new statement has the verb "answered",' do
          it 'returns true' do
            expect(statement_writer(new_statement).write).to be_truthy
          end

          it 'saves the statement in the dynamodb table' do
            statement_writer(new_statement).write
            expect(Xapi::Statement.query_by_attempt(attempt)).to match_array(
              existing_statements << new_statement
            )
          end

          it 'saves all the answered statements in the attempt stored responses' do
            statement_writer(new_statement).write
            expect(SubmissionClient::Submission).to have_received(:create)
            expect(attempt_stored_responses(attempt)).to eq(
              'statements' => [existing_statement.attrs, new_statement.attrs]
            )
          end

          it 'calculates the new attempt time spent' do
            statement_writer(new_statement).write
            expect(Xapi::StatementDuration).to have_received(:new).with(
              Xapi::Statement.query_for_duration(attempt).sort
            )
            expect(statement_duration_mock).to have_received(:duration)
            attempt.reload
            expect(attempt.time_spent).to eq(activity_time_spent)
          end
        end

        context 'when the new statement has a verb other than "answered",' do
          let(:new_statement) { create_statement(verb: Xapi::VERB_ATTEMPTED) }

          it 'returns true' do
            expect(statement_writer(new_statement).write).to be_truthy
          end

          it 'saves the statement in the dynamodb table' do
            statement_writer(new_statement).write
            expect(Xapi::Statement.query_by_attempt(attempt)).to match_array(
              existing_statements << new_statement
            )
          end

          it 'saves all the answered statements in the attempt stored responses' do
            statement_writer(new_statement).write
            expect(SubmissionClient::Submission).not_to have_received(:create)
          end

          it 'calculates the new attempt time spent' do
            statement_writer(new_statement).write
            expect(Xapi::StatementDuration).to have_received(:new).with(
              Xapi::Statement.query_for_duration(attempt).sort
            )
            expect(statement_duration_mock).to have_received(:duration)
            attempt.reload
            expect(attempt.time_spent).to eq(activity_time_spent)
          end
        end

        context 'when statements timestamp are not ordered,' do
          let(:statement_1) { create_statement(timestamp: 8.minutes.ago.utc) }
          let(:statement_2) { create_statement(timestamp: Time.now.utc) }
          let(:statement_3) { create_statement(timestamp: 1.minute.ago.utc) }
          let(:existing_statements) { [statement_1, statement_2] }

          it 'calculates the new attempt time spent with statements ordered by timestamp' do
            statement_writer(statement_3).write
            attempt.reload
            expect(Xapi::StatementDuration).to have_received(:new).with(
              Xapi::Statement.query_for_duration(attempt).sort
            )
            expect(statement_duration_mock).to have_received(:duration)
            expect(attempt.time_spent).to eq(activity_time_spent)
          end
        end
      end

      context 'when the current attempt status id "opened",' do
        let(:saved_response) { {} }
        let(:attempt_status) { AttemptStatus::CODE_OPENED }

        context 'when the new statement verb is "answered"' do
          let(:new_statement) { create_statement(verb: Xapi::VERB_ANSWERED) }

          it 'changes the attempt status to "submitted"' do
            statement_writer(new_statement).write
            attempt.reload
            expect(attempt.status).to eq(:submitted)
          end
        end

        context 'when the student submitted an "answered" statement for all the questions,' do
          let(:content_summary) { { 'matching' => 1 }.to_json }
          let(:new_statement) { create_statement(verb: Xapi::VERB_ANSWERED) }

          it 'changes the attempt status to "completed"' do
            statement_writer(new_statement).write
            attempt.reload
            expect(attempt.status).to eq(:completed)
          end
        end

        context 'when the new statement verb is different than "answered",' do
          it 'does not change the attempt status' do
            [
              Xapi::VERB_INITIALIZED,
              Xapi::VERB_EXPERIENCED,
              Xapi::VERB_ATTEMPTED,
              Xapi::VERB_TERMINATED
            ].each do |verb|
              statement_writer(create_statement(verb: verb)).write
              attempt.reload
              expect(attempt.status).to eq(:opened)
            end
          end
        end

        context 'when the verb is not recognized,' do
          let(:new_statement) { create_statement(verb: unknown_verb) }

          it 'does not change the attempt status' do
            statement_writer(new_statement).write
            attempt.reload
            expect(attempt.status).to eq(:opened)
          end
        end
      end

      context 'when the current attempt status is "submitted",' do
        let(:saved_response) { {} }
        let(:attempt_status) { AttemptStatus::CODE_SUBMITTED }

        context 'when the new statement verb is "answered"' do
          let(:new_statement) { create_statement(verb: Xapi::VERB_ANSWERED) }

          it 'does not change the attempt status' do
            statement_writer(new_statement).write
            attempt.reload
            expect(attempt.status).to eq(:submitted)
          end
        end

        context 'when the student submitted an "answered" statement for all the questions,' do
          let(:content_summary) { { 'matching' => 1 }.to_json }
          let(:new_statement) { create_statement(verb: Xapi::VERB_ANSWERED) }

          it 'changes the attempt status to "completed"' do
            statement_writer(new_statement).write
            attempt.reload
            expect(attempt.status).to eq(:completed)
          end
        end

        context 'when the new statement verb is different than "answered",' do
          it 'does not change the attempt status' do
            [
              Xapi::VERB_INITIALIZED,
              Xapi::VERB_EXPERIENCED,
              Xapi::VERB_ATTEMPTED,
              Xapi::VERB_TERMINATED
            ].each do |verb|
              statement_writer(create_statement(verb: verb)).write
              attempt.reload
              expect(attempt.status).to eq(:submitted)
            end
          end
        end

        context 'when the verb is not recognized,' do
          let(:new_statement) { create_statement(verb: unknown_verb) }

          it 'does not change the attempt status' do
            statement_writer(new_statement).write
            attempt.reload
            expect(attempt.status).to eq(:submitted)
          end
        end
      end

      context 'when the current attempt status is "completed",' do
        let(:saved_response) { {} }
        let(:attempt_status) { AttemptStatus::CODE_COMPLETED }

        context 'when the new statement verb is "answered"' do
          let(:new_statement) { create_statement(verb: Xapi::VERB_ANSWERED) }

          it 'does not change the attempt status' do
            statement_writer(new_statement).write
            attempt.reload
            expect(attempt.status).to eq(:completed)
          end
        end

        context 'when the student submitted an "answered" statement for all the questions,' do
          let(:content_summary) { { 'matching' => 1 }.to_json }
          let(:new_statement) { create_statement(verb: Xapi::VERB_ANSWERED) }

          it 'does not change the attempt status' do
            statement_writer(new_statement).write
            attempt.reload
            expect(attempt.status).to eq(:completed)
          end
        end

        context 'when the new statement verb is different than "answered",' do
          it 'does not change the attempt status' do
            [
              Xapi::VERB_INITIALIZED,
              Xapi::VERB_EXPERIENCED,
              Xapi::VERB_ATTEMPTED,
              Xapi::VERB_TERMINATED
            ].each do |verb|
              statement_writer(create_statement(verb: verb)).write
              attempt.reload
              expect(attempt.status).to eq(:completed)
            end
          end
        end

        context 'when the verb is not recognized,' do
          let(:new_statement) { create_statement(verb: unknown_verb) }

          it 'does not change the attempt status' do
            statement_writer(new_statement).write
            attempt.reload
            expect(attempt.status).to eq(:completed)
          end
        end
      end

      context 'when the statement verb is "answered",' do
        let(:existing_statements) { [existing_statement] }
        let(:new_statement) do
          create_statement(
            result: { score: { raw: 20, min: 0, max: 100 } },
            verb: Xapi::VERB_ANSWERED
          )
        end
        let(:attempt_status) { AttemptStatus::CODE_SUBMITTED }

        it 'calculates the new statement score' do
          statement_writer(new_statement).write
          expect(Smartbook::ScoreCalculator).to have_received(:new)
          expect(score_calculator).to have_received(:points_earned)
        end

        it 'creates a gradebook score action' do
          statement_writer(new_statement).write
          expect(Gradebook::Submission).to have_received(:new).with(
            user, section, activity
          )
          expect(submission_mock).to have_received(:submit_points).with(
            count_attempt: true,
            gradable: true,
            pending: false,
            points_earned: points_earned,
            points_pending: 0,
            points_possible: activity.points_possible,
            submission_length: nil,
            submitted_at: Time.zone.now,
            time_spent: activity_time_spent,
            subactivities_count: 3,
            completed_subactivities_count: 1
          )
        end

        context 'when a statement is saved after the score calculation and before ' \
                'the gradebook score action creation,' do
          before do
            # In order to test this race condition problem, this spec relies on
            # the fact that the tested code will compare `response.answered.count`
            # with `Statement.query_for_answered_count(attempt)`.
            # So we mock the `.query_for_answered_count` method to first save a
            # new statement then call the original implementation.
            # This will make the equality test fail.
            allow(Xapi::Statement).to receive(:query_for_answered_count)
              .with(attempt).and_wrap_original do |m, *args|
              other_statement.store(attempt)
              m.call(*args)
            end
          end

          context 'when a statement with the "answered" verb is saved before ' \
                  'the gradebook score action creation,' do
            let(:other_statement) { create_statement(verb: Xapi::VERB_ANSWERED) }

            it 'does not create a gradebook score action if the ' do
              statement_writer(new_statement).write
              expect(Gradebook::Submission).not_to have_received(:new)
              expect(submission_mock).not_to have_received(:submit_points)
            end
          end

          context 'when a statement with a verb other than "answered" is saved before ' \
                  'the gradebook score action creation,' do
            let(:other_statement) { create_statement(verb: Xapi::VERB_INITIALIZED) }

            it 'does create a gradebook score action' do
              statement_writer(new_statement).write
              expect(Gradebook::Submission).to have_received(:new)
              expect(submission_mock).to have_received(:submit_points)
            end
          end
        end

        context 'when the statement is a response to an instructor graded interaction,' do
          let(:new_statement) { create_audio_recording_statement }

          it 'creates a gradebook score action and set partial_pending to true' do
            statement_writer(new_statement).write
            expect(Gradebook::Submission).to have_received(:new).with(
              user, section, activity
            )
            expect(submission_mock).to have_received(:submit_points).with(
              count_attempt: true,
              gradable: true,
              pending: false,
              points_earned: points_earned,
              points_pending: 0,
              points_possible: activity.points_possible,
              submission_length: nil,
              submitted_at: Time.zone.now,
              time_spent: activity_time_spent,
              subactivities_count: 3,
              completed_subactivities_count: 1,
              partial_pending: true
            )
          end
        end

        context 'when the statement is not modifiable' do
          let(:state_modifiable) { false }

          it 'does not create a gradebook score action' do
            statement_writer(new_statement).write
            expect(Gradebook::Submission).not_to have_received(:new)
          end

          it 'does not save the statement in the dynamodb table' do
            statement_writer(new_statement).write
            expect(Xapi::Statement.query_by_statement_id(new_statement.id)).to be_nil
          end

          it 'returns true' do
            expect(statement_writer(new_statement).write).to be true
          end
        end
      end

      context 'when the statement verb is different than "answered",' do
        let(:saved_response) { {} }
        let(:attempt_status) { AttemptStatus::CODE_SUBMITTED }
        let(:score) { { raw: 20, min: 0, max: 100 } }

        it 'does not create a gradebook score action' do
          [
            Xapi::VERB_INITIALIZED,
            Xapi::VERB_EXPERIENCED,
            Xapi::VERB_ATTEMPTED,
            Xapi::VERB_TERMINATED
          ].each do |verb|
              statement_writer(create_statement(verb: verb, result: { score: score })).write
              expect(Gradebook::Submission).not_to have_received(:new)
          end
        end
      end
    end
  end

  describe '.update_time_tracking' do
    let(:attempt) { build_stubbed(:attempt) }
    let(:statement_writer_mock) { instance_double(described_class) }
    let(:id) { SecureRandom.uuid }

    before do
      allow(XapiUserToken).to receive(:new)
        .with(attempt_id: attempt.id, user_id: user.id, state_modifiable: true).and_return(user_token)
      allow(described_class).to receive(:new).and_return(statement_writer_mock)
      allow(statement_writer_mock).to receive(:write)
      allow(SecureRandom).to receive(:uuid).and_return(id)
    end

    context 'when the state is "pause",' do
      it 'adds an empty statement with the verb "terminated"' do
        described_class.update_time_tracking(:pause, attempt, user, true)
        expect(described_class).to have_received(:new).with(
          id: id,
          actor: { mbox: user_token.mbox },
          verb: { id: Xapi::VERB_TERMINATED },
          object: { objectType: Xapi::Statement::OBJECT_TYPE_ACTIVITY }
        )
        expect(statement_writer_mock).to have_received(:write)
      end
    end

    context 'when the state is "resume",' do
      it 'adds an empty statement with the verb "initialized"' do
        described_class.update_time_tracking(:resume, attempt, user, true)
        expect(described_class).to have_received(:new).with(
          id: id,
          actor: { mbox: user_token.mbox },
          verb: { id: Xapi::VERB_INITIALIZED },
          object: { objectType: Xapi::Statement::OBJECT_TYPE_ACTIVITY }
        )
        expect(statement_writer_mock).to have_received(:write)
      end
    end

    context 'when the state is neither "pause" nor "resume",' do
      it 'raises an error' do
        expect do
          described_class.update_time_tracking(:unknown_state, attempt, user, true)
        end.to raise_error(ArgumentError, "invalid state 'unknown_state'")
      end
    end
  end
end
