describe AttemptStatus, core: true do
  let(:attempt) { Attempt.new }

  describe '#status' do
    it 'returns :unopened for status code of UNOPENED' do
      attempt.status_code = AttemptStatus::CODE_UNOPENED
      expect(attempt.status).to eq(:unopened)
    end

    it 'returns :opened for status code of OPENED' do
      attempt.status_code = AttemptStatus::CODE_OPENED
      expect(attempt.status).to eq(:opened)
    end

    it 'returns :submitted for status code of SUBMITTED' do
      attempt.status_code = AttemptStatus::CODE_SUBMITTED
      expect(attempt.status).to eq(:submitted)
    end

    it 'returns :completed for status code of COMPLETED' do
      attempt.status_code = AttemptStatus::CODE_COMPLETED
      expect(attempt.status).to eq(:completed)
    end

    it 'returns :reset for status code of RESET' do
      attempt.status_code = AttemptStatus::CODE_RESET
      expect(attempt.status).to eq(:reset)
    end
  end

  describe '#expanded_status' do
    it 'returns :unopened for status code of UNOPENED' do
      attempt.status_code = AttemptStatus::CODE_UNOPENED
      expect(attempt.expanded_status).to eq(:unopened)
    end

    it 'returns :opened for status code of OPENED' do
      attempt.status_code = AttemptStatus::CODE_OPENED
      expect(attempt.expanded_status).to eq(:opened)
    end

    it 'returns :incomplete for status code of OPENED with saved data' do
      attempt.status_code = AttemptStatus::CODE_OPENED
      attempt.save_record_length = 100
      expect(attempt.expanded_status).to eq(:incomplete)
    end

    it 'returns :incomplete for status code of SUBMITTED' do
      attempt.status_code = AttemptStatus::CODE_SUBMITTED
      expect(attempt.expanded_status).to eq(:incomplete)
    end

    it 'returns :completed for status code of COMPLETED' do
      attempt.status_code = AttemptStatus::CODE_COMPLETED
      expect(attempt.expanded_status).to eq(:completed)
    end

    it 'returns :reset for status code of RESET' do
      attempt.status_code = AttemptStatus::CODE_RESET
      expect(attempt.expanded_status).to eq(:reset)
    end
  end

  describe '#attempted?' do
    it 'is true if status is submitted' do
      attempt.status_code = AttemptStatus::CODE_SUBMITTED
      expect(attempt.attempted?).to be_truthy
    end

    it 'is true if status is completed' do
      attempt.status_code = AttemptStatus::CODE_COMPLETED
      expect(attempt.attempted?).to be_truthy
    end

    it 'is false if status is opened' do
      attempt.status_code = AttemptStatus::CODE_OPENED
      expect(attempt.attempted?).to be_falsey
    end

    it 'is false if status is unopened' do
      attempt.status_code = AttemptStatus::CODE_UNOPENED
      expect(attempt.attempted?).to be_falsey
    end

    it 'returns true if attempt is reset' do
      attempt.status_code = AttemptStatus::CODE_RESET
      expect(attempt.attempted?).to be_truthy
    end
  end

  describe '#complete?' do
    context 'with a practice attempt,' do
      let(:practice_attempt) { Attempt.new(practice: true) }

      it 'is true when practice_complete is true' do
        practice_attempt.practice_complete = true
        expect(practice_attempt).to be_complete
      end

      it 'is false when practice_complete is false' do
        practice_attempt.practice_complete = false
        expect(practice_attempt).not_to be_complete
      end

      it 'is false when practice_complete is not set' do
        expect(practice_attempt).not_to be_complete
      end
    end

    context 'with a non practice attempt,' do
      it 'returns false for status code of UNOPENED' do
        attempt.status_code = AttemptStatus::CODE_UNOPENED
        expect(attempt).not_to be_complete
      end

      it 'returns false for status code of OPENED' do
        attempt.status_code = AttemptStatus::CODE_OPENED
        expect(attempt).not_to be_complete
      end

      it 'returns false for status code of SUBMITTED' do
        attempt.status_code = AttemptStatus::CODE_SUBMITTED
        expect(attempt).not_to be_complete
      end

      it 'returns true for status code of COMPLETED' do
        attempt.status_code = AttemptStatus::CODE_COMPLETED
        expect(attempt).to be_complete
      end
    end
  end

  describe '#completed?' do
    it 'returns false for status code of UNOPENED' do
      attempt.status_code = AttemptStatus::CODE_UNOPENED
      expect(attempt).not_to be_completed
    end

    it 'returns false for status code of OPENED' do
      attempt.status_code = AttemptStatus::CODE_OPENED
      expect(attempt).not_to be_completed
    end

    it 'returns false for status code of SUBMITTED' do
      attempt.status_code = AttemptStatus::CODE_SUBMITTED
      expect(attempt).not_to be_completed
    end

    it 'returns true for status code of COMPLETED' do
      attempt.status_code = AttemptStatus::CODE_COMPLETED
      expect(attempt).to be_completed
    end
  end

  describe '#submitted?' do
    it 'returns false for status code of UNOPENED' do
      attempt.status_code = AttemptStatus::CODE_UNOPENED
      expect(attempt).not_to be_submitted
    end

    it 'returns false for status code of OPENED' do
      attempt.status_code = AttemptStatus::CODE_OPENED
      expect(attempt).not_to be_submitted
    end

    it 'returns true for status code of SUBMITTED' do
      attempt.status_code = AttemptStatus::CODE_SUBMITTED
      expect(attempt).to be_submitted
    end

    it 'returns false for status code of COMPLETED' do
      attempt.status_code = AttemptStatus::CODE_COMPLETED
      expect(attempt).not_to be_submitted
    end
  end

  describe '#unsubmitted?' do
    it 'returns true if the status code is OPENED' do
      attempt.status_code = AttemptStatus::CODE_OPENED
      expect(attempt).to be_unsubmitted
    end

    it 'returns true if the status code is UNOPENED' do
      attempt.status_code = AttemptStatus::CODE_UNOPENED
      expect(attempt).to be_unsubmitted
    end

    it 'returns false if the status code is SUBMITTED' do
      attempt.status_code = AttemptStatus::CODE_SUBMITTED
      expect(attempt).not_to be_unsubmitted
    end

    it 'returns false if the status code is COMPLETED' do
      attempt.status_code = AttemptStatus::CODE_COMPLETED
      expect(attempt).not_to be_unsubmitted
    end
  end

  describe '#reset?' do
    it 'returns true if attempt has been reset' do
      attempt.status_code = AttemptStatus::CODE_RESET
      expect(attempt).to be_reset
    end

    it 'returns false if status is any other state' do
      attempt.status_code = AttemptStatus::CODE_UNOPENED
      expect(attempt).not_to be_reset
      attempt.status_code = AttemptStatus::CODE_OPENED
      expect(attempt).not_to be_reset
      attempt.status_code = AttemptStatus::CODE_SUBMITTED
      expect(attempt).not_to be_reset
      attempt.status_code = AttemptStatus::CODE_COMPLETED
      expect(attempt).not_to be_reset
    end
  end
end
