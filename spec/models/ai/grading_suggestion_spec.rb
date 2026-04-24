describe AI::GradingSuggestion do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:question_label) }
    it { is_expected.to validate_presence_of(:incorrect_text) }
    it { is_expected.to validate_presence_of(:error_explanation) }

    context 'when creating a new record,' do
      let(:prompt) { create(:ai_grading_suggestion_prompt) }

      it 'is valid if the prompt is not blank' do
        entry = build(:ai_grading_suggestion, prompt:)

        expect(entry).to be_valid
      end

      it 'is invalid if the prompt is blank' do
        entry = build(:ai_grading_suggestion, prompt: nil)

        entry.valid?

        expect(entry.errors[:prompt]).to eq(['is required'])
      end
    end

    context 'when updating an exiting record,' do
      let(:entry) { create(:ai_grading_suggestion) }
      let(:prompt) { create(:ai_grading_suggestion_prompt) }

      it 'is valid if the prompt is not blank' do
        entry.prompt = prompt

        expect(entry).to be_valid
      end

      it 'is valid if the prompt is blank' do
        entry.prompt = nil

        expect(entry).to be_valid
      end
    end

    context 'when the entry has not been reviewed by anyone' do
      let(:entry) { build(:ai_grading_suggestion, reviewed_by: nil) }

      it 'is valid if reviewed_status is blank' do
        entry.reviewed_status = nil

        expect(entry).to be_valid
      end

      it 'is invalid if reviewed_status is not blank' do
        entry.reviewed_status = described_class::ACCEPTED_STATUS

        entry.valid?

        expect(entry.errors[:reviewed_status]).to eq(['must be blank'])
      end
    end

    context 'when the entry has been reviewed by someone' do
      let(:user) { create(:user) }
      let(:entry) { build(:ai_grading_suggestion, reviewed_by: user) }

      it 'is valid if reviewed_status is "accepted"' do
        entry.reviewed_status = described_class::ACCEPTED_STATUS

        expect(entry).to be_valid
      end

      it 'is valid if reviewed_status is "rejected"' do
        entry.reviewed_status = described_class::REJECTED_STATUS

        expect(entry).to be_valid
      end

      it 'is invalid if reviewed_status is blank' do
        entry.reviewed_status = ''

        entry.valid?

        expect(entry.errors[:reviewed_status]).to include('is required')
      end

      it 'is invalid if reviewed_status is neither "applied" nor "rejected"' do
        entry.reviewed_status = 'other'

        entry.valid?

        expect(entry.errors[:reviewed_status]).to eq(
          ['must be included in the list']
        )
      end
    end

    context 'when the entry has not been rated' do
      let(:entry) { build(:ai_grading_suggestion, rating_category: nil) }

      it 'is valid if the rater is blank' do
        entry.rated_by = nil

        expect(entry).to be_valid
      end

      it 'is invalid if rater is not blank' do
        entry.rated_by = create(:user)

        entry.valid?

        expect(entry.errors[:rated_by]).to eq(['must be blank'])
      end
    end

    context 'when the entry has been rated with a rating category' do
      let(:rating_category) { create(:ai_suggestion_rating_category) }
      let(:entry) { build(:ai_grading_suggestion, rating_category:) }

      it 'is valid if the rater is not blank' do
        entry.rated_by = create(:user)

        expect(entry).to be_valid
      end

      it 'is invalid if rater is blank' do
        entry.rated_by = nil

        entry.valid?

        expect(entry.errors[:rated_by]).to eq(['is required'])
      end
    end

    context 'when the entry has been rated with a comment' do
      let(:rating_category) { create(:ai_suggestion_rating_category) }
      let(:entry) { build(:ai_grading_suggestion, rating_comment: 'blah') }

      it 'is valid if the rater is not blank' do
        entry.rated_by = create(:user)

        expect(entry).to be_valid
      end

      it 'is invalid if rater is blank' do
        entry.rated_by = nil

        entry.valid?

        expect(entry.errors[:rated_by]).to eq(['is required'])
      end
    end

    context 'when the entry is internal' do
      let(:grading_suggestion_input) { create(:ai_grading_suggestion_input) }
      let(:entry) { build(:ai_grading_suggestion, grading_suggestion_input:) }

      it 'is valid if the reviewed status is blank' do
        expect(entry).to be_valid
      end

      it 'is invalid if the reviewed status is not blank' do
        entry.reviewed_status = described_class::ACCEPTED_STATUS

        entry.valid?

        expect(entry.errors[:reviewed_status]).to eq(['must be blank'])
      end

      it 'is valid if the rating category is blank' do
        expect(entry).to be_valid
      end

      it 'is invalid if the rating category is not blank' do
        entry.rating_category = create(:ai_suggestion_rating_category)

        entry.valid?

        expect(entry.errors[:rating_category]).to eq(['must be blank'])
      end

      it 'is valid if the rating comment is blank' do
        expect(entry).to be_valid
      end

      it 'is invalid if the rating comment is not blank' do
        entry.rating_comment = 'this is wrong'

        entry.valid?

        expect(entry.errors[:rating_comment]).to eq(['must be blank'])
      end
    end

    describe 'the incorrect_text_begin_offset attribute' do
      let(:entry) { build(:ai_grading_suggestion) }

      it 'is valid when incorrect_text_begin_offset is blank' do
        entry.incorrect_text_begin_offset = ''

        expect(entry).to be_valid
      end

      it 'is invalid when incorrect_text_begin_offset is not an integer' do
        entry.incorrect_text_begin_offset = 32.3

        entry.valid?

        expect(entry.errors[:incorrect_text_begin_offset]).to eq(
          ['must be an integer']
        )
      end

      it 'is valid when incorrect_text_begin_offset is a positive integer' do
        entry.incorrect_text_begin_offset = 32

        expect(entry).to be_valid
      end

      it 'is valid when incorrect_text_begin_offset is equal to -1' do
        entry.incorrect_text_begin_offset = -1

        expect(entry).to be_valid
      end

      it 'is invalid when incorrect_text_begin_offset is negative' do
        entry.incorrect_text_begin_offset = -3

        entry.valid?

        expect(entry.errors[:incorrect_text_begin_offset]).to eq(
          ['must be greater than or equal to -1']
        )
      end
    end
  end

  describe 'callbacks' do
    it 'sets the language_code from the language_code of a specified program' do
      program = create(:program, language_code: 'zh')

      entry = create(:ai_grading_suggestion, program:)

      expect(entry.language_code).to eq('zh')
    end

    context 'when the entry is reviewed by someone' do
      it 'sets reviewed_at to the current time' do
        user = create(:user)

        entry = create(
          :ai_grading_suggestion,
          reviewed_by: user,
          reviewed_status: described_class::ACCEPTED_STATUS
        )

        expect(entry.reviewed_at).to be_within(9.seconds).of(Time.current)
      end
    end

    context 'when the entry has not been reviewed' do
      it 'does not set reviewed_at to the current time' do
        entry = create(:ai_grading_suggestion, reviewed_by: nil)

        expect(entry.reviewed_at).to be_nil
      end
    end

    context 'when the entry is rated by someone' do
      it 'sets rated_at to the current time' do
        user = create(:user)

        entry = create(
          :ai_grading_suggestion,
          rated_by: user,
          rating_category: create(:ai_suggestion_rating_category)
        )

        expect(entry.rated_at).to be_within(9.seconds).of(Time.current)
      end
    end

    context 'when the entry has not been rated' do
      it 'does not set rated_at to the current time' do
        entry = create(:ai_grading_suggestion, rated_by: nil)

        expect(entry.rated_at).to be_nil
      end
    end
  end

  describe '#incorrect_text_end_offset' do
    it 'returns nil when the begin offset is blank' do
      entry = build(:ai_grading_suggestion, incorrect_text_begin_offset: '')

      expect(entry.incorrect_text_end_offset).to be_nil
    end

    it 'returns -1 when the begin offset is -1' do
      entry = build(:ai_grading_suggestion, incorrect_text_begin_offset: -1)

      expect(entry.incorrect_text_end_offset).to eq(-1)
    end

    it 'returns the end offset + the length of the incorrect text when the begin offset is positive' do
      entry = build(:ai_grading_suggestion, incorrect_text_begin_offset: 3)

      expect(entry.incorrect_text_end_offset).to eq(
        entry.incorrect_text_begin_offset + entry.incorrect_text.length
      )
    end
  end
end
