describe StudentVideoChatWorkTransfer do
  let(:school) { create(:school) }
  let(:course) { create(:course, school: school) }
  let(:section_from) { create(:section, course: course) }
  let(:section_to) { create(:section, course: course) }
  let(:dynamo_wrapper) { instance_double(DynamoWrapper) }
  let(:student) { create(:student) }
  let(:partner) { create(:student) }
  let(:activity) { create(:partner_chat_activity) }
  let(:attempt) { create(:attempt, user: student, activity: activity) }
  let(:archive_id) { SecureRandom.uuid }
  let(:response) do
    instance_double(
      PartnerChatRecording,
      id: 1010,
      recording_path: "46068002/#{archive_id}/archive.mp4"
    )
  end
  let(:results) do
    instance_double(
      MaestroActivityEngine::ActivityContent::Results,
      first: { response: response }
    )
  end
  let(:work_transfer) do
    described_class.new(
      attempt: attempt,
      new_section_id: section_to.id
    )
  end

  before do
    allow(attempt).to receive(:results).and_return(results)
    allow(DynamoWrapper).to receive(:new).and_return(dynamo_wrapper)
    allow(dynamo_wrapper).to receive(:find).and_return([])
    allow(dynamo_wrapper).to receive(:update)
  end

  describe '#process' do
    it 'uses the correct dynamo table' do
      work_transfer.process

      expect(DynamoWrapper).to have_received(:new).with(
        table: 'tokbox-recordings'
      )
    end

    it 'searches for dynamo records for the correct archive id' do
      allow(dynamo_wrapper).to receive(:find).and_return([])

      work_transfer.process

      expect(dynamo_wrapper).to have_received(:find).with(
        primary_key: [{ archive_id: archive_id }],
        selected_attributes: %w[user_1 user_2 users]
      )
    end

    it 'does nothing when no record is found in the dynamo table' do
      allow(dynamo_wrapper).to receive(:find).and_return([])

      work_transfer.process

      expect(dynamo_wrapper).not_to have_received(:update)
    end

    context 'when dynamodb records exist and the activity is a partner chat' do
      context 'when the user id is found in the user_1 attribute' do
        it 'updates the record with the new section id' do
          allow(dynamo_wrapper).to receive(:find).and_return(
            [
              {
                'user_1' => {
                  'id' => student.id.to_s,
                  'section_id' => section_from.id.to_s
                },
                'user_2' => {
                  'id' => partner.id.to_s,
                  'section_id' => section_from.id.to_s
                }
              }
            ]
          )

          work_transfer.process

          expect(dynamo_wrapper).to have_received(:update).with(
            primary_key: { archive_id: archive_id },
            item_updates: {
              'user_1' => {
                'id' => student.id.to_s, 'section_id' => section_to.id.to_s
              }
            }
          )
        end
      end

      context 'when the user id is found in the user_2 attribute' do
        it 'updates the record with the new section id' do
          allow(dynamo_wrapper).to receive(:find).and_return(
            [
              {
                'user_1' => {
                  'id' => partner.id.to_s,
                  'section_id' => section_from.id.to_s
                },
                'user_2' => {
                  'id' => student.id.to_s,
                  'section_id' => section_from.id.to_s
                }
              }
            ]
          )

          work_transfer.process

          expect(dynamo_wrapper).to have_received(:update).with(
            primary_key: { archive_id: archive_id },
            item_updates: {
              'user_2' => {
                'id' => student.id.to_s, 'section_id' => section_to.id.to_s
              }
            }
          )
        end
      end

      context 'when the user id is not found in the users attribute' do
        it 'does not update the record' do
          other_student = create(:student)

          allow(dynamo_wrapper).to receive(:find).and_return(
            [
              {
                'user_1' => {
                  'id' => other_student.id.to_s,
                  'section_id' => section_from.id.to_s
                },
                'user_2' => {
                  'id' => partner.id.to_s,
                  'section_id' => section_from.id.to_s
                }
              }
            ]
          )

          work_transfer.process

          expect(dynamo_wrapper).not_to have_received(:update)
        end
      end
    end

    context 'when dynamodb records exist and the activity is a solo video recording' do
      let(:activity) { create(:solo_video_recording_activity) }

      it 'does not update the record when the user id is not found in the user_1 attribute' do
        other_student = create(:student)

        allow(dynamo_wrapper).to receive(:find).and_return(
          [
            {
              'user_1' => {
                'id' => other_student.id.to_s,
                'section_id' => section_from.id.to_s
              }
            }
          ]
        )

        work_transfer.process

        expect(dynamo_wrapper).not_to have_received(:update)
      end

      it 'updates the record when the user id is found in the user_1 attribute' do
        allow(dynamo_wrapper).to receive(:find).and_return(
          [
            {
              'user_1' => {
                'id' => student.id.to_s,
                'section_id' => section_from.id.to_s
              }
            }
          ]
        )

        work_transfer.process

        expect(dynamo_wrapper).to have_received(:update).with(
          primary_key: { archive_id: archive_id },
          item_updates: {
            'user_1' => {
              'id' => student.id.to_s, 'section_id' => section_to.id.to_s
            }
          }
        )
      end
    end

    context 'when dynamodb records exist and the activity is a group chat' do
      let(:activity) { create(:group_chat_activity) }
      let(:partner_student_1) { create(:student) }
      let(:partner_student_2) { create(:student) }

      it 'does not update the record when the user id is not found in the user_1 or users attribute' do
        other_student = create(:student)

        allow(dynamo_wrapper).to receive(:find).and_return(
          [
            {
              'user_1' => {
                'id' => other_student.id.to_s,
                'section_id' => section_from.id.to_s
              },
              'users' => [
                { 'section_id' => section_from.id.to_s, 'id' => partner_student_1.id.to_s },
                { 'section_id' => section_from.id.to_s, 'id' => partner_student_2.id.to_s }
              ]
            }
          ]
        )

        work_transfer.process

        expect(dynamo_wrapper).not_to have_received(:update)
      end

      it 'updates the record when the user id is found in the user_1 attribute' do
        allow(dynamo_wrapper).to receive(:find).and_return(
          [
            {
              'user_1' => {
                'id' => student.id.to_s,
                'section_id' => section_from.id.to_s
              },
              'users' => [
                { 'section_id' => section_from.id.to_s, 'id' => partner_student_1.id.to_s },
                { 'section_id' => section_from.id.to_s, 'id' => partner_student_2.id.to_s }
              ]
            }
          ]
        )

        work_transfer.process

        expect(dynamo_wrapper).to have_received(:update).with(
          primary_key: { archive_id: archive_id },
          item_updates: {
            'user_1' => {
              'id' => student.id.to_s, 'section_id' => section_to.id.to_s
            }
          }
        )
      end

      it 'updates the record when the user id is found in the users attribute' do
        allow(dynamo_wrapper).to receive(:find).and_return(
          [
            {
              'user_1' => {
                'id' => partner_student_1.id.to_s,
                'section_id' => section_from.id.to_s
              },
              'users' => [
                { 'section_id' => section_from.id.to_s, 'id' => student.id.to_s },
                { 'section_id' => section_from.id.to_s, 'id' => partner_student_2.id.to_s }
              ]
            }
          ]
        )

        work_transfer.process

        expect(dynamo_wrapper).to have_received(:update).with(
          primary_key: { archive_id: archive_id },
          item_updates: {
            'users' => [
              { 'section_id' => section_from.id.to_s, 'id' => partner_student_2.id.to_s },
              { 'section_id' => section_to.id.to_s, 'id' => student.id.to_s }
            ]
          }
        )
      end
    end
  end

  describe '#errors?' do
    it 'returns false when updating the dynamo record succeeds' do
      allow(dynamo_wrapper).to receive(:errors?).and_return(false)

      work_transfer.process

      expect(work_transfer.errors?).to be_falsey
    end

    it 'returns true when updating the dynamo record fails' do
      allow(dynamo_wrapper).to receive(:errors?).and_return(true)

      work_transfer.process

      expect(work_transfer.errors?).to be_truthy
    end
  end

  describe '#error_messages' do
    it 'returns false when updating the dynamo record succeeds' do
      allow(dynamo_wrapper).to receive(:errors?).and_return(false)
      allow(dynamo_wrapper).to receive(:error_messages).and_return([])

      work_transfer.process

      expect(work_transfer.error_messages).to eq([])
    end

    it 'returns true when updating the dynamo record fails' do
      allow(dynamo_wrapper).to receive(:errors?).and_return(true)
      allow(dynamo_wrapper).to receive(:error_messages).and_return(
        [
          'error 1',
          'error 2'
        ]
      )

      work_transfer.process

      expect(work_transfer.error_messages).to match_array(
        ['error 1', 'error 2']
      )
    end
  end
end
