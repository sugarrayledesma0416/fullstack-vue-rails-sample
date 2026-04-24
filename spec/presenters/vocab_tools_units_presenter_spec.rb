describe VocabToolsUnitsPresenter do
  describe '#units' do
    let(:media_item) { create(:media_item) }
    let(:lesson) { create(:lesson) }
    let(:other_lesson) { create(:lesson) }
    let(:unit) do
      create(:unit, media_item: media_item,
                     lessons: [lesson, other_lesson])
    end

    let(:program) { create(:program, units: [unit]) }
    let(:word) { create(:default_vocabulary_word, lesson: lesson) }
    let(:section) { create(:section) }
    let(:presenter) { described_class.new(section, program) }

    context 'when a unit includes a lesson with no default vocabulary words' do
      it 'returns all lessons (even ones without words)' do
        result = presenter.payload[:units][0]

        expect(result).to have_key(:lessons)
        expect(result[:lessons]).to be_an(Array)
        expect(result[:lessons].size).to eq(2)
      end
    end
  end
end
