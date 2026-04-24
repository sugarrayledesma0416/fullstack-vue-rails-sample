describe AI::ConversationSessionMessagesUpdater do
  describe '#update' do
    let(:session) { create(:ai_conversation_session) }

    def create_updater(messages_attrs)
      described_class.new(session:, messages_attrs:)
    end

    context 'when a message already exists,' do
      let!(:message) { create(:ai_conversation_session_message, session:) }

      context 'when the current audio_file_path is blank,' do
        it 'updates the audio_file_path attribute when present' do
          updater = create_updater([{ guid: message.guid, audio_file_path: 'some/path'}])

          expect do
            updater.update
          end.to change { message.reload.audio_file_path }.to 'some/path'
        end
      end

      context 'when the current audio_file_path is present,' do
        before do
          message.update!(audio_file_path: 'some/already/existing/path')
        end

        it 'does not update the audio_file_path attribute when present' do
          updater = create_updater([{ guid: message.guid, audio_file_path: 'some/path'}])

          expect do
            updater.update
          end.to not_change(message.reload, :audio_file_path )
        end

        it 'does not update the audio_file_path attribute when blank' do
          updater = create_updater([{ guid: message.guid, audio_file_path: ''}])

          expect do
            updater.update
          end.to not_change(message.reload, :audio_file_path )
        end
      end

      it 'does not update the role when present' do
        updater = create_updater([{ guid: message.guid, role: 'assistant'}])

        expect do
          updater.update
        end.to not_change(message.reload, :role )
      end

      it 'does not update the message when present' do
        updater = create_updater([{ guid: message.guid, message_text: 'some new message'}])

        expect do
          updater.update
        end.to not_change(message.reload, :message_text )
      end

      it 'does not update the session_id when present' do
        other_session = create(:ai_conversation_session)
        updater = create_updater([{ guid: message.guid, session_id: other_session.id}])

        expect do
          updater.update
        end.to not_change(message.reload, :session_id )
      end
    end

    context 'when a message does not exist,' do
      let(:message_attrs) do
        {
          guid: SecureRandom.uuid,
          role: 'user',
          audio_file_path: 'some/path'
        }
      end

      it 'creates a new message' do
        updater = create_updater([message_attrs])

        expect do
          updater.update
        end.to change(AI::ConversationSessionMessage, :count).by(1)
      end

      it 'sets the new message attributes,' do
        updater = create_updater([message_attrs])

        updater.update

        expect(AI::ConversationSessionMessage.last).to have_attributes(
          message_attrs.merge(session_id: session.id)
        )
      end

      it 'raises an error when some attributes are invalid,' do
        updater = create_updater([message_attrs.merge(role: 'invalid role')])

        expect do
          updater.update
        end.to raise_error(
          ActiveRecord::RecordInvalid,
          'Validation failed: Role must be included in the list'
        )
      end
    end
  end
end
