describe AttemptSubmission do
  describe '#submission_partition_key' do
    let(:attempt) { create(:attempt) }
    let(:date) { '2014-01-03' }

    it 'returns a string based on the attempt created_at' do
      Timecop.freeze(Time.parse("#{date} 08:00:00")) do
        expect(attempt.submission_partition_key).to eql(date)
      end
    end

    it 'returns a date adjusted for utc' do
      Timecop.freeze(Time.parse("#{date} 22:00:00")) do
        expect(attempt.submission_partition_key).to eql(1.day.from_now.strftime('%Y-%m-%d'))
      end
    end

    it 'returns utc date when a user with a timezone mapping to the previous day submits' do
      date = Time.parse('2015-06-29 08:37:27 UTC')
      Timecop.freeze(date) do
        attempt
      end

      Timecop.freeze(date) do
        Time.use_zone('Hawaii') do
          expect(Attempt.first.submission_partition_key).to eql('2015-06-29')
        end
      end
    end

    it 'returns utc date when a user with a timezone mapping to the next day submits' do
      date = Time.parse('2015-06-29 23:37:27 UTC')
      Timecop.freeze(date) do
        attempt
      end

      Timecop.freeze(date) do
        Time.use_zone('Tokyo') do
          expect(Attempt.first.submission_partition_key).to eql('2015-06-29')
        end
      end
    end
  end

  describe '#set_submission' do
    let(:attempt) { create(:attempt) }

    it 'records submitted attempts' do
      attempt.set_submission(0, 250, nil)
      attempt.reload
      expect(attempt.offset_bytes).to eq(0)
      expect(attempt.record_length).to eq(250)
    end

    it 'records temporary data (save state)' do
      attempt.set_submission(250, 350, nil, :unsubmitted)
      attempt.reload
      expect(attempt.save_offset_bytes).to eq(250)
      expect(attempt.save_record_length).to eq(350)
    end

    it 'nulls out prior saved data pointers when submitted' do
      attempt.set_submission(600, 250, nil, :unsubmitted)
      attempt.reload
      expect(attempt.save_offset_bytes).to eq(600)
      expect(attempt.save_record_length).to eq(250)

      attempt.set_submission(850, 200, nil, :submitted)
      attempt.reload
      expect(attempt.offset_bytes).to eq 850
      expect(attempt.record_length).to eq 200
      expect(attempt.save_offset_bytes).to be_nil
      expect(attempt.save_record_length).to be_nil
      expect(attempt.saved_submission_id).to be_nil
    end
  end

  describe '#reset_submission' do
    let(:attempt) { create(:attempt, record_length: 500, offset_bytes: 200) }

    it 'resets offset, length and submission id to nil' do
      attempt.reset_submission
      expect(attempt.record_length).to be_nil
      expect(attempt.offset_bytes).to be_nil
      expect(attempt.submission_id).to be_nil
    end
  end

  describe '#submitted_values?' do
    let(:attempt) { create(:attempt) }

    it 'returns true if attempt has submitted values' do
      attempt.record_length = 100
      expect(attempt.submitted_values?).to be_truthy
    end

    it 'returns true if attempt has submitted values' do
      attempt.submission_id = 1234
      expect(attempt.submitted_values?).to be_truthy
    end

    it 'returns false if nothing has been submitted' do
      attempt.record_length = nil
      expect(attempt.submitted_values?).to be_falsey

      attempt.record_length = 0
      expect(attempt.submitted_values?).to be_falsey
    end

    it 'returns false if nothing has been submitted' do
      attempt.submission_id = nil
      expect(attempt.submitted_values?).to be_falsey
    end
  end

  describe '#saved_values?' do
    let(:attempt) { create(:attempt) }

    it 'returns true if attempt has saved values' do
      attempt.save_record_length = 100
      expect(attempt.saved_values?).to be_truthy
    end

    it 'returns true if attempt has saved_submission_id' do
      attempt.saved_submission_id = 5678
      expect(attempt.saved_values?).to be_truthy
    end

    it 'returns false if nothing has been saved' do
      attempt.save_record_length = nil
      expect(attempt.saved_values?).to be_falsey

      attempt.save_record_length = 0
      expect(attempt.saved_values?).to be_falsey
    end

    it 'returns false if nothing has been saved' do
      attempt.saved_submission_id = nil
      expect(attempt.saved_values?).to be_falsey
    end
  end
end
