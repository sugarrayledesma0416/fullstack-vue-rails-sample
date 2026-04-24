# rubocop:disable RSpec/MultipleMemoizedHelpers
describe InstantFeedbackResults do
  include SharedSubmissionClientStubs

  let(:activity) { create(:activity) }
  let(:attempt) { create(:attempt, activity: activity) }
  let(:activity_content_scope) { MaestroActivityEngine::ActivityContent }

  let(:content_object) do
    activity_content_scope::FillInTheBlanksContent.new
  end

  let(:inputs) do
    [
      {
        label: 'question_1',
        response: 'test response'
      },
      {
        label: 'question_2',
        response: 'another response'
      }
    ]
  end

  let(:results) do
    described_class.new(
      activity:,
      attempt:,
      disable_enhanced_feedback: false,
      inputs:
    )
  end

  def create_results_with_responses(combined_responses = {})
    activity_content_scope::Results.new.tap do |memo|
      combined_responses.each do |label, response|
        memo.add(label: label, response: response)
      end
    end
  end

  describe '#payload' do
    let(:response_params) do
      {
        'question_1' => 'test response',
        'question_2' => 'another response'
      }
    end

    let(:validation_results) do
      create_results_with_responses(response_params)
    end

    before do
      # Mock the content_object method on the real activity
      allow(activity).to receive(:content_object).and_return(content_object)
      content_object.language = 'en'

      allow(content_object).to receive(:validate_responses).and_return(
        validation_results
      )

      allow(validation_results).to receive(:correctness)
        .with('question_1')
        .and_return(true)

      allow(validation_results).to receive(:correctness)
        .with('question_2')
        .and_return(false)

      stub_submission_find({}, nil)
      stub_submission_create
    end

    context 'when content object supports sample_answer' do
      let(:content_object) do
        activity_content_scope::OpenEndedContent.new
      end

      before do
        allow(content_object).to receive(:sample_answer)
          .and_return('sample answer 1')

        allow(content_object).to receive(:sample_answer)
          .with('question_1')
          .and_return('sample answer 1')

        allow(content_object).to receive(:sample_answer)
          .with('question_2')
          .and_return('sample answer 2')
      end

      it 'returns a complete payload with sample answer for each input' do
        expected_payload = {
          'question_1' => {
            correctness: true,
            sample_answer: 'sample answer 1'
          },
          'question_2' => {
            correctness: false,
            sample_answer: 'sample answer 2'
          }
        }

        expect(results.payload).to eq(expected_payload)
      end
    end

    context 'when content object supports best_answer and ' \
            'enhanced_feedback_items' do
      before do
        allow(activity).to receive(:content_object).and_return(content_object)
        content_object.language = 'en'

        allow(content_object).to receive(:best_answer)
          .with('question_1', 'test response')
          .and_return('correct answer 1')

        allow(content_object).to receive(:best_answer)
          .with('question_2', 'another response')
          .and_return('correct answer 2')

        allow(content_object).to receive(:enhanced_feedback_items)
          .with('question_1', 'test response', attempt.scoring_ruleset)
          .and_return(['feedback item 1', 'feedback item 2'])

        allow(content_object).to receive(:enhanced_feedback_items)
          .with('question_2', 'another response', attempt.scoring_ruleset)
          .and_return(['feedback item 3'])
      end

      it 'returns a complete payload with all feedback types for each input' do
        expected_payload = {
          'question_1' => {
            correctness: true,
            correct_answer: 'correct answer 1',
            enhanced_feedback_items: ['feedback item 1', 'feedback item 2']
          },
          'question_2' => {
            correctness: false,
            correct_answer: 'correct answer 2',
            enhanced_feedback_items: ['feedback item 3']
          }
        }

        expect(results.payload).to eq(expected_payload)
      end
    end

    context 'when enhanced feedback is disabled' do
      let(:results) do
        described_class.new(
          activity:,
          attempt:,
          disable_enhanced_feedback: true,
          inputs:
        )
      end

      before do
        allow(activity).to receive(:content_object).and_return(content_object)
        content_object.language = 'en'

        allow(content_object).to receive(:best_answer)
          .with('question_1', 'test response')
          .and_return('correct answer 1')

        allow(content_object).to receive(:best_answer)
          .with('question_2', 'another response')
          .and_return('correct answer 2')
      end

      it 'returns payload without enhanced feedback for each input' do
        expected_payload = {
          'question_1' => {
            correctness: true,
            correct_answer: 'correct answer 1'
          },
          'question_2' => {
            correctness: false,
            correct_answer: 'correct answer 2'
          }
        }

        expect(results.payload).to eq(expected_payload)
      end
    end

    context 'when content object supports no additional feedback' do
      let(:content_object) do
        MaestroActivityEngine::ActivityContent::Content.new
      end

      before do
        # Mock the content_object method on the real activity
        allow(activity).to receive(:content_object).and_return(content_object)
        content_object.language = 'en'
      end

      it 'returns payload with only correctness for each input' do
        expected_payload = {
          'question_1' => {
            correctness: true
          },
          'question_2' => {
            correctness: false
          }
        }

        expect(results.payload).to eq(expected_payload)
      end
    end

    context 'when attempt has empty stored_responses' do
      let(:attempt) { create(:attempt, activity:) }
      let(:submission_id) { 123 }

      before do
        attempt.submission_id = submission_id
        stub_submission_find({}, submission_id)
        allow(content_object).to receive(:best_answer).and_return('mocked answer')
      end

      it 'uses only response_params for validation' do
        results.payload

        expect(content_object).to have_received(:validate_responses).with(
          response_params, results.send(:scoring_ruleset), :saved
        )
      end

      it 'calls SubmissionClient::Submission.create with correct data' do
        pending 'until re_try views are updated to handle saved_responses'
        results.payload

        expect(submission_class).to have_received(:create).with(
          attempt_id: attempt.id,
          partition_key: attempt.submission_partition_key,
          data: response_params.to_json
        )
      end
    end

    context 'when attempt has stored_responses' do
      let(:attempt) { create(:attempt, activity:) }
      let(:submission_id) { 456 }
      let(:new_saved_submission_id) { 1001 }

      let(:stored_responses) do
        {
          'question_1' => 'stored response 1',
          'question_3' => 'stored response 3'
        }
      end

      let(:validation_results) do
        create_results_with_responses(stored_responses.merge(response_params))
      end

      before do
        attempt.submission_id = submission_id
        stub_submission_find(stored_responses, submission_id)
        stub_submission_create(new_saved_submission_id)
        allow(content_object).to receive(:best_answer).and_return('mocked answer')
      end

      it 'merges stored_responses with response_params for validation' do
        expected_params = {
          'question_1' => 'test response', # response_params overrides stored
          'question_2' => 'another response', # from response_params only
          'question_3' => 'stored response 3' # from stored_responses only
        }

        results.payload

        expect(content_object).to have_received(:validate_responses).with(
          expected_params, results.send(:scoring_ruleset), :saved
        )
      end

      it 'calls SubmissionClient::Submission.create with merged data' do
        pending 'until re_try views are updated to handle saved_responses'
        expected_params = {
          'question_1' => 'test response', # response_params overrides stored
          'question_2' => 'another response', # from response_params only
          'question_3' => 'stored response 3' # from stored_responses only
        }

        results.payload

        expect(submission_class).to have_received(:create) do |args|
          args[:attempt_id] == attempt.id &&
            args[:partition_key] == attempt.submission_partition_key &&
            JSON.parse(args[:data]) == expected_params
        end
      end

      it 'updates saved_submission_id with the returned submission id' do
        pending 'until re_try views are updated to handle saved_responses'
        results.payload

        attempt.reload
        expect(attempt.saved_submission_id).to eq(new_saved_submission_id)
      end
    end

    context 'when attempt has saved_responses' do
      let(:attempt) { create(:attempt, activity:) }
      let(:saved_submission_id) { 789 }
      let(:new_saved_submission_id) { 1002 }

      let(:saved_responses) do
        {
          'question_1' => 'saved response 1',
          'question_4' => 'saved response 4'
        }
      end

      let(:validation_results) do
        create_results_with_responses(saved_responses.merge(response_params))
      end

      before do
        attempt.saved_submission_id = saved_submission_id
        stub_submission_find(saved_responses, saved_submission_id)
        stub_submission_create(new_saved_submission_id)
        allow(content_object).to receive(:best_answer).and_return('mocked answer')
      end

      it 'merges saved_responses with response_params for validation' do
        expected_params = {
          'question_1' => 'test response', # response_params overrides saved
          'question_2' => 'another response', # from response_params only
          'question_4' => 'saved response 4' # from saved_responses only
        }

        results.payload

        expect(content_object).to have_received(:validate_responses).with(
          expected_params, results.send(:scoring_ruleset), :saved
        )
      end

      it 'calls SubmissionClient::Submission.create with merged data' do
        pending 'until re_try views are updated to handle saved_responses'
        expected_params = {
          'question_1' => 'test response', # response_params overrides saved
          'question_2' => 'another response', # from response_params only
          'question_4' => 'saved response 4' # from saved_responses only
        }

        results.payload

        expect(submission_class).to have_received(:create) do |args|
          args[:attempt_id] == attempt.id &&
            args[:partition_key] == attempt.submission_partition_key &&
            JSON.parse(args[:data]) == expected_params
        end
      end

      it 'updates saved_submission_id with the returned submission id' do
        pending 'until re_try views are updated to handle saved_responses'
        results.payload

        attempt.reload
        expect(attempt.saved_submission_id).to eq(new_saved_submission_id)
      end
    end

    context 'when attempt has both saved_responses and stored_responses' do
      let(:attempt) { create(:attempt, activity:) }
      let(:submission_id) { 101 }
      let(:saved_submission_id) { 102 }
      let(:new_saved_submission_id) { 1003 }

      let(:stored_responses) do
        {
          'question_1' => 'stored response 1',
          'question_3' => 'stored response 3'
        }
      end

      let(:saved_responses) do
        {
          'question_1' => 'saved response 1',
          'question_4' => 'saved response 4'
        }
      end

      let(:validation_results) do
        create_results_with_responses(saved_responses.merge(response_params))
      end

      before do
        attempt.submission_id = submission_id
        attempt.saved_submission_id = saved_submission_id
        stub_submission_find(stored_responses, submission_id)
        stub_submission_find(saved_responses, saved_submission_id)
        stub_submission_create(new_saved_submission_id)
        allow(content_object).to receive(:best_answer).and_return('mocked answer')
      end

      it 'prioritizes saved_responses over stored_responses for validation' do
        expected_params = {
          'question_1' => 'test response', # response_params overrides saved
          'question_2' => 'another response', # from response_params only
          'question_4' => 'saved response 4' # from saved_responses only
        }

        results.payload

        expect(content_object).to have_received(:validate_responses).with(
          expected_params, results.send(:scoring_ruleset), :saved
        )
      end

      it 'calls SubmissionClient::Submission.create with prioritized data' do
        pending 'until re_try views are updated to handle saved_responses'
        expected_params = {
          'question_1' => 'test response', # response_params overrides saved
          'question_2' => 'another response', # from response_params only
          'question_4' => 'saved response 4' # from saved_responses only
        }

        results.payload

        expect(submission_class).to have_received(:create) do |args|
          args[:attempt_id] == attempt.id &&
            args[:partition_key] == attempt.submission_partition_key &&
            JSON.parse(args[:data]) == expected_params
        end
      end

      it 'updates saved_submission_id with the returned submission id' do
        pending 'until re_try views are updated to handle saved_responses'
        results.payload

        attempt.reload
        expect(attempt.saved_submission_id).to eq(new_saved_submission_id)
      end
    end

    context 'when attempt has empty saved_responses' do
      let(:attempt) { create(:attempt, activity:) }
      let(:submission_id) { 103 }
      let(:saved_submission_id) { 104 }
      let(:new_saved_submission_id) { 1004 }

      let(:stored_responses) do
        {
          'question_1' => 'stored response 1',
          'question_3' => 'stored response 3'
        }
      end

      let(:validation_results) do
        create_results_with_responses(stored_responses.merge(response_params))
      end

      before do
        attempt.submission_id = submission_id
        attempt.saved_submission_id = saved_submission_id
        stub_submission_find(stored_responses, submission_id)
        stub_submission_find({}, saved_submission_id) # empty saved_responses
        stub_submission_create(new_saved_submission_id)
        allow(content_object).to receive(:best_answer).and_return('mocked answer')
      end

      it 'falls back to stored_responses when saved_responses is empty' do
        expected_params = {
          'question_1' => 'test response', # response_params overrides stored
          'question_2' => 'another response', # from response_params only
          'question_3' => 'stored response 3' # from stored_responses only
        }

        results.payload

        expect(content_object).to have_received(:validate_responses).with(
          expected_params, results.send(:scoring_ruleset), :saved
        )
      end

      it 'calls SubmissionClient::Submission.create with fallback data' do
        pending 'until re_try views are updated to handle saved_responses'
        expected_params = {
          'question_1' => 'test response', # response_params overrides stored
          'question_2' => 'another response', # from response_params only
          'question_3' => 'stored response 3' # from stored_responses only
        }

        results.payload

        expect(submission_class).to have_received(:create) do |args|
          args[:attempt_id] == attempt.id &&
            args[:partition_key] == attempt.submission_partition_key &&
            JSON.parse(args[:data]) == expected_params
        end
      end

      it 'updates saved_submission_id with the returned submission id' do
        pending 'until re_try views are updated to handle saved_responses'
        results.payload

        attempt.reload
        expect(attempt.saved_submission_id).to eq(new_saved_submission_id)
      end
    end

    context 'when attempt is PreviewAttempt (no stored_responses method)' do
      let(:attempt) do
        PreviewAttempt.new(
          activity:,
          section: Section.section_zero,
          user: create(:student)
        )
      end

      before do
        allow(activity).to receive(:content_object).and_return(content_object)
        content_object.language = 'en'
        allow(content_object).to receive(:best_answer).and_return('mocked answer')
      end

      it 'uses only response_params for validation' do
        results.payload

        expect(content_object).to have_received(:validate_responses).with(
          response_params, results.send(:scoring_ruleset), :saved
        )
      end

      it 'does not call SubmissionClient::Submission.create for PreviewAttempt' do
        results.payload

        expect(submission_class).not_to have_received(:create)
      end
    end

    describe 'scoring ruleset handling' do
      let(:inputs) { [{ label: 'question_1', response: 'test' }] }
      let(:user) { create(:student) }
      let(:response_params) { { 'question_1' => 'test' } }

      let(:validation_results) do
        create_results_with_responses(response_params)
      end

      before do
        allow(activity).to receive(:content_object).and_return(content_object)
        content_object.language = 'en'

        allow(content_object).to receive_messages(
          best_answer: 'foo',
          validate_responses: validation_results
        )
        stub_submission_create(1005)
      end

      context 'when attempt responds to scoring_ruleset' do
        let(:attempt) { create(:attempt, activity:) }
        let(:ruleset) { create(:scoring_ruleset) }

        let(:results) do
          described_class.new(
            activity:,
            attempt:,
            disable_enhanced_feedback: false,
            inputs:
          )
        end

        before do
          allow(attempt).to receive(:scoring_ruleset).and_return(ruleset)
        end

        it 'does not raise an error' do
          expect { results.payload }.not_to raise_error
        end

        it 'uses the attempt scoring_ruleset' do
          results.payload

          expect(content_object).to have_received(:validate_responses).with(
            { 'question_1' => 'test' }, ruleset, :saved
          )
        end
      end

      context 'when attempt does not respond to scoring_ruleset' do
        let(:attempt) do
          PreviewAttempt.new(activity:, section: Section.section_zero, user:)
        end

        let(:default_scoring_ruleset) { ScoringRuleset.default }

        let(:results) do
          described_class.new(
            activity:,
            attempt:,
            disable_enhanced_feedback: false,
            inputs:
          )
        end

        before do
          allow(activity).to receive(:content_object).and_return(content_object)
          content_object.language = 'en'
        end

        it 'does not raise an error' do
          expect { results.payload }.not_to raise_error
        end

        it 'uses ScoringRuleset.default' do
          results.payload

          expect(content_object).to have_received(:validate_responses)
            .with({ 'question_1' => 'test' }, default_scoring_ruleset, :saved)
        end

        it 'does not call SubmissionClient::Submission.create for PreviewAttempt' do
          results.payload

          expect(submission_class).not_to have_received(:create)
        end
      end

      context 'when activity content object language is Chinese' do
        let(:attempt) { create(:attempt, activity:) }
        let(:ruleset) { create(:scoring_ruleset) }

        let(:results) do
          described_class.new(
            activity:,
            attempt:,
            disable_enhanced_feedback: false,
            inputs:
          )
        end

        before do
          content_object.language = 'zh'
          allow(attempt).to receive(:scoring_ruleset).and_return(ruleset)
        end

        it 'does not raise an error' do
          expect { results.payload }.not_to raise_error
        end

        it 'sets chinese to true on the scoring ruleset' do
          results.payload

          expect(ruleset).to be_chinese
        end
      end

      context 'when activity content object language is not Chinese' do
        let(:attempt) { create(:attempt, activity:) }
        let(:ruleset) { create(:scoring_ruleset) }

        let(:results) do
          described_class.new(
            activity:,
            attempt:,
            disable_enhanced_feedback: false,
            inputs:
          )
        end

        before do
          content_object.language = 'en'
          allow(attempt).to receive(:scoring_ruleset).and_return(ruleset)
        end

        it 'does not raise an error' do
          expect { results.payload }.not_to raise_error
        end

        it 'does not modify the chinese setting on the scoring ruleset' do
          results.payload

          expect(ruleset).not_to be_chinese
        end
      end

      context 'when using PreviewAttempt (does not respond to scoring_ruleset) ' \
              'with Chinese language' do
        let(:attempt) do
          PreviewAttempt.new(
            activity:,
            section: Section.section_zero,
            user:
          )
        end
        let(:default_scoring_ruleset) { ScoringRuleset.default }

        let(:results) do
          described_class.new(
            activity:,
            attempt:,
            disable_enhanced_feedback: false,
            inputs:
          )
        end

        before do
          allow(activity).to receive(:content_object).and_return(content_object)
          allow(ScoringRuleset).to receive(:default).and_return(
            default_scoring_ruleset
          )

          content_object.language = 'zh'
        end

        it 'does not raise an error' do
          expect { results.payload }.not_to raise_error
        end

        it 'uses ScoringRuleset.default' do
          results.payload

          expect(ScoringRuleset).to have_received(:default)
        end

        it 'sets chinese to true on the scoring ruleset' do
          results.payload

          expect(default_scoring_ruleset).to be_chinese
        end

        it 'does not call SubmissionClient::Submission.create for PreviewAttempt' do
          results.payload

          expect(submission_class).not_to have_received(:create)
        end
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
