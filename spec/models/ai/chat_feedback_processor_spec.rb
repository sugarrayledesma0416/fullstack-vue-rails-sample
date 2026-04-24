require 'rails_helper'

RSpec.describe AI::ChatFeedbackProcessor do
  let(:program) { create(:program) }
  let(:activity) { create(:activity) }
  let(:instructor) { create(:instructor) }
  let(:chat_session) { create(:ai_conversation_session) }
  let(:chat_message) { create(:ai_conversation_session_message, guid: 'msg123', session: chat_session) }
  let(:rating_category) { create(:ai_suggestion_rating_category, id: 1, label: 'inappropriate') }

  let(:valid_params) do
    {
      flaggedItems: [
        {
          guid: 'msg123',
          reason_id: rating_category.id,
          comment: 'This is inappropriate'
        }
      ],
      additionalFeedback: "Overall feedback comment",
      sessionId: chat_session.id
    }.to_json
  end

  subject do
    described_class.new(
      params_json: valid_params,
      program: program,
      activity: activity,
      instructor: instructor
    )
  end

  describe '#process!' do
    before do
      rating_category # ensure rating category exists
      chat_message # ensure chat message exists
    end

    context 'with valid params' do
      it 'creates a new feedback flag' do
        expect { subject.process! }.to change(AI::ChatFeedbackFlag, :count).by(1)
      end

      it 'sets the correct attributes on the feedback flag' do
        subject.process!
        feedback = AI::ChatFeedbackFlag.last

        expect(feedback).to have_attributes(
          program_id: program.id,
          activity_id: activity.id,
          message_guid: 'msg123',
          graded_by_id: instructor.id,
          comment: 'This is inappropriate',
          ai_virtual_chat_session_messages_id: chat_message.id,
          ai_suggestion_rating_categories_id: rating_category.id
        )
      end

      context 'when feedback flag already exists' do
        let!(:existing_feedback) do
          create(:ai_chat_feedback_flag,
            program: program,
            activity: activity,
            message_guid: 'msg123'
          )
        end

        it 'updates the existing feedback flag' do
          expect { subject.process! }.not_to change(AI::ChatFeedbackFlag, :count)

          existing_feedback.reload
          expect(existing_feedback.comment).to eq('This is inappropriate')
          expect(existing_feedback.graded_by_id).to eq(instructor.id)
        end
      end
    end

    context 'with invalid params' do
      context 'with invalid JSON' do
        let(:invalid_params) { '{invalid_json' }

        subject do
          described_class.new(
            params_json: invalid_params,
            program: program,
            activity: activity,
            instructor: instructor
          )
        end

        it 'returns nil' do
          expect(subject.process!).to be_nil
        end

        it 'handles the error gracefully' do
          expect { subject.process! }.not_to raise_error
        end
      end

      context 'with missing message guid' do
        let(:params_without_guid) do
          {
            flaggedItems: [
              {
                reason_id: rating_category.id,
                comment: 'This is inappropriate'
              }
            ]
          }.to_json
        end

        subject do
          described_class.new(
            params_json: params_without_guid,
            program: program,
            activity: activity,
            instructor: instructor
          )
        end

        it 'skips processing the item' do
          expect { subject.process! }.not_to change(AI::ChatFeedbackFlag, :count)
        end
      end

      context 'with non-existent chat message' do
        let(:params_with_invalid_guid) do
          {
            flaggedItems: [
              {
                guid: 'non_existent_guid',
                reason_id: rating_category.id,
                comment: 'This is inappropriate'
              }
            ]
          }.to_json
        end

        subject do
          described_class.new(
            params_json: params_with_invalid_guid,
            program: program,
            activity: activity,
            instructor: instructor
          )
        end

        it 'skips processing the item' do
          expect { subject.process! }.not_to change(AI::ChatFeedbackFlag, :count)
        end
      end
    end

    context 'with multiple items' do
      let(:chat_message2) { create(:ai_conversation_session_message, guid: 'msg456') }
      let(:multiple_params) do
        {
          flaggedItems: [
            {
              guid: 'msg123',
              reason_id: rating_category.id,
              comment: 'First comment'
            },
            {
              guid: 'msg456',
              reason_id: rating_category.id,
              comment: 'Second comment'
            }
          ]
        }.to_json
      end

      before do
        chat_message2
      end

      subject do
        described_class.new(
          params_json: multiple_params,
          program: program,
          activity: activity,
          instructor: instructor
        )
      end

      it 'processes all items' do
        expect { subject.process! }.to change(AI::ChatFeedbackFlag, :count).by(2)
      end
    end

    context 'with overall feedback' do
      let(:chat_session) { create(:ai_conversation_session) }

      let(:params_with_overall_feedback) do
        {
          flaggedItems: [],
          additionalFeedback: "Overall feedback comment",
          sessionId: chat_session.id
        }.to_json
      end

      subject do
        described_class.new(
          params_json: params_with_overall_feedback,
          program: program,
          activity: activity,
          instructor: instructor
        )
      end

      it 'creates a new overall feedback' do
        expect { subject.process! }.to change(AI::ChatOverallFeedback, :count).by(1)
      end

      it 'sets the correct attributes on the overall feedback' do
        subject.process!
        feedback = AI::ChatOverallFeedback.last

        expect(feedback).to have_attributes(
          program_id: program.id,
          activity_id: activity.id,
          graded_by_id: instructor.id,
          comment: "Overall feedback comment",
          ai_virtual_chat_sessions_id: chat_session.id
        )
      end

      context 'when overall feedback already exists' do
        let!(:existing_feedback) do
          create(:ai_chat_overall_feedback,
            program: program,
            activity: activity,
            graded_by_id: instructor.id
          )
        end

        it 'updates the existing feedback' do
          expect { subject.process! }.not_to change(AI::ChatOverallFeedback, :count)

          existing_feedback.reload
          expect(existing_feedback.comment).to eq("Overall feedback comment")
          expect(existing_feedback.ai_virtual_chat_sessions_id).to eq(chat_session.id)
        end
      end

      context 'with invalid session id' do
        let(:params_with_invalid_session) do
          {
            flaggedItems: [],
            additionalFeedback: "Overall feedback comment",
            sessionId: 999999
          }.to_json
        end

        subject do
          described_class.new(
            params_json: params_with_invalid_session,
            program: program,
            activity: activity,
            instructor: instructor
          )
        end

        it 'skips processing the overall feedback' do
          expect { subject.process! }.not_to change(AI::ChatOverallFeedback, :count)
        end

        it 'returns nil when session is not found' do
          response = subject.process!
          expect(response).to be_nil
        end
      end
    end

    context 'with both flagged items and overall feedback' do
      let(:chat_session) { create(:ai_conversation_session) }
      let(:chat_message) { create(:ai_conversation_session_message, guid: 'msg123') }

      let(:params_with_both) do
        {
          flaggedItems: [
            {
              guid: 'msg123',
              reason_id: rating_category.id,
              comment: 'This is inappropriate'
            }
          ],
          additionalFeedback: "Overall feedback comment",
          sessionId: chat_session.id
        }.to_json
      end

      subject do
        described_class.new(
          params_json: params_with_both,
          program: program,
          activity: activity,
          instructor: instructor
        )
      end

      before do
        rating_category
        chat_message
        chat_session
      end

      it 'processes both types of feedback' do
        expect {
          subject.process!
        }.to change(AI::ChatFeedbackFlag, :count).by(1)
        .and change(AI::ChatOverallFeedback, :count).by(1)
      end

      it 'creates both feedbacks with correct attributes' do
        subject.process!

        flag = AI::ChatFeedbackFlag.last
        expect(flag.comment).to eq('This is inappropriate')

        overall = AI::ChatOverallFeedback.last
        expect(overall.comment).to eq('Overall feedback comment')
      end
    end
  end
end
