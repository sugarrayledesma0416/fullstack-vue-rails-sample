require 'tasks/demo_submission_repartition'

describe DemoSubmissionRepartition do
  let(:student_1) { create(:student) }
  let(:model_demo_student_1) { create(:user, username: 'model_demo_student_1') }
  let(:model_demo_student_2) { create(:user, username: 'model_demo_student_2') }

  describe '#model_student_attempts' do
    context 'when there are attempts with submission_ids' do
      let!(:attempt_1) do
        create(:attempt, user: model_demo_student_1, created_at: DateTime.parse('2020-01-01'),
                         submission_id: 1)
      end
      let!(:attempt_2) do
        create(:attempt, user: model_demo_student_2, created_at: DateTime.parse('2020-12-31'),
                         submission_id: 2)
      end
      let!(:attempt_3) do
        create(:attempt, user: model_demo_student_2, created_at: DateTime.parse('2021-01-01'),
                         submission_id: 4)
      end

      before do
        create(:attempt, user: student_1, created_at: DateTime.parse('2020-05-01'), submission_id: 3)
      end

      it 'returns only attempts for users model_demo_student_1 and model_demo_student_2' do
        demo_sub_repartitioner = described_class.new(year: 2020)
        expect(demo_sub_repartitioner.model_student_attempts).to contain_exactly(attempt_1,
                                                                                 attempt_2)
      end

      it 'returns only attempts for the specified year' do
        demo_sub_repartitioner = described_class.new(year: 2021)
        expect(demo_sub_repartitioner.model_student_attempts).to contain_exactly(attempt_3)
      end
    end

    context 'when there are no attempts with submission_ids' do
      let!(:attempt_1) do
        create(:attempt, user: model_demo_student_1, created_at: DateTime.parse('2020-01-01'),
                         submission_id: nil)
      end
      let!(:attempt_2) do
        create(:attempt, user: model_demo_student_2, created_at: DateTime.parse('2020-12-31'),
                         submission_id: nil)
      end

      it 'returns no attempts' do
        demo_sub_repartitioner = described_class.new(year: 2020)
        expect(demo_sub_repartitioner.model_student_attempts).to be_empty
      end
    end
  end

  describe '#update_attempt' do
    let(:current_date) { '2023-05-01' }
    let!(:attempt) do
      create(:attempt, id: 1, user: model_demo_student_1, created_at: DateTime.parse('2020-01-01'),
                       submission_id: 1)
    end

    before do
      allow(SubmissionClient::Submission).to receive(:find)
        .with(attempt.submission_id, attempt.submission_partition_key)
        .and_return([SubmissionClient::Submission.new('id' => 1, 'data' => { foo: 'bar' })])
      allow(SubmissionClient::Submission).to receive(:create).and_return(
        SubmissionClient::Submission.new('id' => 2)
      )
    end

    it 'creates a new submission record and updates the attempt' do
      Timecop.freeze(Time.zone.parse("#{current_date} 00:00:00")) do
        updated_attempt = described_class.new(year: 2020, dry_run: false).update_attempt(attempt)

        expect(SubmissionClient::Submission).to have_received(:find).with(1, '2020-01-01')
        expect(SubmissionClient::Submission).to have_received(:create).with(
          attempt_id: attempt.id,
          partition_key: current_date,
          data: '{"foo":"bar"}'
        )
        expect(updated_attempt.created_at.to_s).to start_with("#{current_date} 00:00:00")
        expect(updated_attempt.submission_partition_key).to eq(current_date)
        expect(updated_attempt.submission_id).to eq(2)
      end
    end
  end
end
