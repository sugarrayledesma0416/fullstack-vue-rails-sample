describe AI::SuggestionRatingDetail do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:question_label) }
    it { is_expected.to belong_to(:attempt) }
    it { is_expected.to belong_to(:activity) }
    it { is_expected.to belong_to(:program) }
    it { is_expected.to belong_to(:updated_by) }

    it 'denormalize the activity from the attempt' do
      attempt = create(:attempt)

      detail = build(:ai_suggestion_rating_detail, attempt:, activity: nil)

      detail.valid?

      expect(detail.activity).to eq(attempt.activity)
    end

    it 'denormalize the program from the attempt' do
      attempt = create(:attempt)

      detail = build(:ai_suggestion_rating_detail, attempt:, program: nil)

      detail.valid?

      expect(detail.program).to eq(attempt.activity.program)
    end
  end

  describe '#comment' do
    let(:detail) { build(:ai_suggestion_rating_detail) }

    it 'strips out white spaces' do
      detail.comment = '   something   '

      expect(detail.comment).to eq('something')
    end
  end
end
