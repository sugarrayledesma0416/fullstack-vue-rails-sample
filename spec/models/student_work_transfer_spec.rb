describe StudentWorkTransfer do
  let(:school) { create(:school) }
  let(:course) { create(:course, school: school) }
  let(:section_from) { create(:section, course: course) }
  let(:section_to) { create(:section, course: course) }

  describe '#initialize' do
    it 'accepts integers instead of objects' do
      student = create(:student)

      work_transfer = StudentWorkTransfer.new(student.id, section_from.id, section_to.id)
      expect(work_transfer.student).to      eq(student)
      expect(work_transfer.section_from).to eq(section_from)
      expect(work_transfer.section_to).to   eq(section_to)
    end

    it 'accepts passing in zero for section_from' do
      student = create(:student)

      expect{ StudentWorkTransfer.new(student, 0, section_to) }.not_to raise_error
    end
  end

  describe '#process' do
    let(:student) { create(:student) }
    let(:activity) { create(:activity) }
    let(:work_transfer) { described_class.new(student, section_from, section_to) }

    let(:lossless_client) do
      instance_double(Lossless::Client, transfer_student_work: true)
    end

    before do
      enrollment = double('enrollment', :id => 123, :unblock_access! => true)
      allow(student).to receive(:active_enrollment_by_section).and_return(enrollment)
      allow(GradebookEngine::GradebookAPI).to receive(:transfer_student_work)
      allow(Lossless::Client).to receive(:new).and_return(lossless_client)
    end

    it 'transfers lossless recordings' do
      work_transfer.process

      expect(lossless_client).to have_received(:transfer_student_work).with(
        student.id, section_from, section_to
      )
    end

    context "when enrollment does not require a work transfer" do
      before do
        allow(work_transfer).to receive(:requires_work_transfer?).and_return(false)
      end

      it "unblocks the enrollment" do
        expect(work_transfer).to receive(:unblock_access!)
        work_transfer.process
      end

      it "sets logger data for logstash" do
        expected_hash = {section_from_guid: section_from.guid,
                         section_to_guid: section_to.guid,
                         user_guid: student.guid}
        work_transfer.process
        expect(work_transfer.logger_data).to match hash_including(expected_hash)
      end
    end

    context "when enrollment requires a work transfer" do
      before do
        allow(work_transfer).to receive(:requires_work_transfer?).and_return(true)
      end

      it "sets logger data for logstash" do
        expected_hash = {section_from_guid: section_from.guid,
                         section_to_guid: section_to.guid,
                         user_guid: student.guid}
        work_transfer.process
        expect(work_transfer.logger_data).to match hash_including(expected_hash)
      end

      context 'when an error occurs' do
        it 'raises an error' do
          error = StandardError.new('wah wah')
          allow(work_transfer).to receive(:transfer_scores).and_raise(error)
          allow(work_transfer).to receive(:prefer_bulk_attempt_transfer?).and_return(false)
          expect { work_transfer.process }.to raise_error error
        end
      end

      context 'when student is not enrolled,' do
        let(:section_from) { Section.section_zero }
        let!(:attempt) { create(:attempt, user_id: student.id,
                                          section_id: section_from.id,
                                          status_code: AttemptStatus::CODE_COMPLETED) }
        let(:enrollment) { double('enrollment', :id => 123, :unblock_access! => true) }

        before do
          allow(student).to receive(:active_enrollment_by_section).and_return(enrollment)
        end

        it 'removes attempts for the user with section_id of zero' do
          expect { work_transfer.process }.to change(Attempt, :count).by(-1)
        end

        it 'does not run a work transfer on GB v2' do
          expect(GradebookEngine::GradebookAPI).to_not receive(:transfer_student_work)
          work_transfer.process
        end

        it 'unblocks the new enrollment' do
          expect(enrollment).to receive(:unblock_access!)
          work_transfer.process
        end
      end

      context 'when student is coming from an existing section,' do
        let(:section_from) { create(:section) }

        context "#transfer_scores" do
          it 'transfers score actions to the new section' do
            expect(GradebookEngine::GradebookAPI).to receive(:transfer_student_work)
                                                 .with(user: student,
                                                       section_from: section_from,
                                                       section_to: section_to)
            work_transfer.process
          end
        end

        context '#move_attempts_and_responses' do
          let(:section_from_attrs) { {user_id: student.id,
                                      activity_id: activity.id,
                                      section_id: section_from.id,
                                      status_code: AttemptStatus::CODE_COMPLETED} }
          let(:section_to_attrs) { section_from_attrs.merge(section_id: section_to.id) }
          let!(:section_from_attempt) { create(:attempt, section_from_attrs) }

          it 'moves attempt records to the new section' do
            expect(Attempt.where(section_from_attrs).count).to eq 1
            expect(Attempt.where(section_to_attrs).count).to eq 0
            work_transfer.process
            expect(Attempt.where(section_from_attrs).count).to eq 0
            expect(Attempt.where(section_to_attrs).count).to eq 1
          end

          it 'replaces existing attempts in the new section' do
            create(:attempt, section_to_attrs)
            expect(Attempt.where(section_from_attrs).count).to eq 1
            expect(Attempt.where(section_to_attrs).count).to eq 1
            work_transfer.process
            expect(Attempt.where(section_from_attrs).count).to eq 0
            expect(Attempt.where(section_to_attrs).count).to eq 1
          end
        end

        context '#clean_up_old_attempts' do
          it 'removes left-over unsubmitted attempt records' do
            att0 = create(:attempt, status_code: AttemptStatus::CODE_OPENED,
                                    user_id: student.id,
                                    section_id: section_from.id)
            att2 = create(:attempt, user: student,
                                    section: section_from,
                                    activity: activity,
                                    status_code: AttemptStatus::CODE_COMPLETED)
            att3 = create(:attempt, status_code: AttemptStatus::CODE_RESET,
                                    user_id: student.id,
                                    section_id: section_from.id)
            att4 = create(:attempt, status_code: AttemptStatus::CODE_STARTED,
                                    user_id: student.id,
                                    section_id: section_from.id)
            # submitted attempts are moved to section_to so we should see the others removed.
            expect { work_transfer.process }.to change(Attempt, :count).by(-3)
            expect(Attempt.where(section_id: section_to,
                                 user_id: student.id)).to eq [att2]
            expect(Attempt.where(section_id: section_from,
                                 user_id: student.id).count).to eq 0
          end
        end
      end
    end

    context 'when original section is archived' do
      it 'does not error' do
        section_from.update(is_archived: true)
        allow(student).to receive(:active_enrollment_by_section).and_call_original

        create('enrollment', user_id: student.id,
                             section_id: section_to.id,
                             state: 'enrolled',
                             blocked: true)
        work_transfer = StudentWorkTransfer.new(student.id, section_from.id, section_to.id)

        expect { work_transfer.process }.to_not raise_error
        expected_hash = {section_from_guid: section_from.guid,
                         section_to_guid: section_to.guid,
                         user_guid: student.guid}
        expect(work_transfer.logger_data).to match hash_including(expected_hash)
        expect(student.active_enrollment_by_section(section_to)).to_not be_blocked
      end
    end

    context 'when the student has standards results records' do
      let(:cms_activity_id) { '4f9d974' }

      before do
        create(
          :standards_results,
          user_id: student.id,
          section_id: section_from.id,
          cms_activity_id: cms_activity_id
        )
      end

      it 'moves standards results records to the new section' do
        expect(StandardsResults.by_section(section_from)
                               .by_student(student).count).to eq 1
        expect(StandardsResults.by_section(section_to)
                               .by_student(student).count).to eq 0
        work_transfer.process
        expect(StandardsResults.by_section(section_from)
                               .by_student(student).count).to eq 0
        expect(StandardsResults.by_section(section_to)
                               .by_student(student).count).to eq 1
      end

      it 'replaces standards results records in the new section' do
        create(
          :standards_results,
          user_id: student.id,
          section_id: section_to.id,
          cms_activity_id: cms_activity_id
        )

        expect(StandardsResults.by_section(section_from)
                               .by_student(student).count).to eq 1
        expect(StandardsResults.by_section(section_to)
                               .by_student(student).count).to eq 1
        work_transfer.process
        expect(StandardsResults.by_section(section_from)
                               .by_student(student).count).to eq 0
        expect(StandardsResults.by_section(section_to)
                               .by_student(student).count).to eq 1
      end
    end

    context 'when the student has attempts for chat activities' do
      let(:activity) { create(:partner_chat_activity) }
      let!(:attempt) do
        create(
          :attempt,
          user: student,
          activity: activity,
          section: section_from,
          status_code: AttemptStatus::CODE_COMPLETED
        )
      end
      let(:video_chat_work_transfer) do
        instance_double(StudentVideoChatWorkTransfer)
      end

      before do
        allow(StudentVideoChatWorkTransfer).to receive(:new).and_return(
          video_chat_work_transfer
        )
        allow(video_chat_work_transfer).to receive(:process)
        allow(video_chat_work_transfer).to receive(:errors?).and_return(false)
      end

      RSpec.shared_examples 'activity is a chat activity of type' do |activity_type|
        it 'transfer the student video chat work' do
          work_transfer.process

          expect(StudentVideoChatWorkTransfer).to have_received(:new).with(
            attempt: attempt,
            new_section_id: section_to.id
          )
          expect(video_chat_work_transfer).to have_received(:process)
          expect(attempt.activity.activity_type).to eq activity_type
        end
      end

      context 'when the activity is a partner chat' do
        include_examples 'activity is a chat activity of type', 'partner_chat'
      end

      context 'when the activity is a solo video recording' do
        let(:activity) { create(:solo_video_recording_activity) }
        include_examples 'activity is a chat activity of type', 'solo_video_recording'
      end

      context 'when the activity is a group chat' do
        let(:activity) { create(:group_chat_activity) }
        include_examples 'activity is a chat activity of type', 'group_chat'
      end

      it 'does not raise error when transferring the student video chat work ' \
         'succeeds' do
        expect do
          work_transfer.process
        end.not_to raise_error
      end

      it 'raises error when transferring the student video chat work failed' do
        error_messages = [
          'something wrong happened',
          'sone other error'
        ]
        allow(video_chat_work_transfer).to receive(:errors?).and_return(true)
        allow(video_chat_work_transfer).to receive(:error_messages).and_return(
          error_messages
        )
        expect do
          work_transfer.process
        end.to raise_error(
          StandardError,
          'Failed to transfer student video chat work: ' \
          "#{error_messages.join(', ')}."
        )
      end
    end
  end

  describe '#unblock_access!' do
    let(:student) { build_stubbed(:student) }
    let(:work_transfer) { StudentWorkTransfer.new(student, section_from, section_to) }

    it 'sends a call to unblock access' do
      enrollment = create(:active_enrollment, :user => student, :blocked => true, :section => section_to)
      allow(student).to receive(:active_enrollment_by_section).and_return(enrollment)
      expect(enrollment).to receive(:unblock_access!)
      work_transfer.unblock_access!
    end
  end
end
