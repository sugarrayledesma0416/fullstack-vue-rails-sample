describe RubricPresenter do
  let(:doc) do
    Nokogiri::XML.parse(File.new('spec/fixtures/xml/solo_video_recording_with_rubric.xml'))
  end
  let(:document_modifier) { doc.xpath('//rubric') }
  let(:rubric) { MaestroActivityEngine::TagParser::Rubric.new(doc, '//rubric').parse.first }
  let(:attempt_opened) { create(:attempt_opened) }
  let(:attempt_completed) { create(:attempt_completed) }
  let(:presenter_no_attempt) { described_class.new(rubric) }
  let(:presenter_attempt_opened) { described_class.new(rubric, attempt_opened) }
  let(:presenter_attempt_completed) { described_class.new(rubric, attempt_completed) }

  let(:criteria_score_json) do
    { 'Content': '4', 'Organization': '3', 'Accuracy': '5' }.to_json
  end

  before do
    create(
      :rubric_criteria_score,
      attempt_id: attempt_completed.id,
      criteria_score_json: criteria_score_json
    )
  end

  describe '#scores' do
    it 'returns nil if there is no attempt' do
      expect(presenter_no_attempt.scores).to be nil
    end

    it 'returns nil if there is an incomplete attempt' do
      expect(presenter_attempt_opened.scores).to be nil
    end

    it 'returns criteria scores if there is a completed attempt' do
      expected_hash = JSON.parse(criteria_score_json)
      expect(presenter_attempt_completed.scores).to eq(expected_hash)
    end
  end

  describe '#show_scores?' do
    it 'returns nil if there is no attempt' do
      expect(presenter_no_attempt.show_scores?).to be false
    end

    it 'returns nil if there is an incomplete attempt' do
      expect(presenter_attempt_opened.show_scores?).to be false
    end

    it 'returns true if there is a completed attempt' do
      expect(presenter_attempt_completed.show_scores?).to be true
    end
  end
end
