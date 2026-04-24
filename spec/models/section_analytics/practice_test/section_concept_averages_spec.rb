describe SectionAnalytics::PracticeTest::SectionConceptAverages do
  let(:students) { 3.times { create(:student) } }
  let(:concept) { create(:study_plan_concept) }
  let(:section_concept) { described_class.new(concept, students) }
  let(:scores) { [25, 80, 90] }
  let(:summative_scores) { [45, 100, 100] }

  before do
    allow(section_concept).to receive(:scores).and_return(scores)
    allow(section_concept).to receive(:summative_scores).and_return(summative_scores)
  end

  def average(numbers)
    numbers.reduce(0, :+) / numbers.count
  end

  describe '#average' do
    it 'returns the average score for the students' do
      expect(section_concept.average).to eq(average(scores))
    end

    context 'when there are no scores for the section' do
      let(:scores) { [] }

      it 'returns 0' do
        expect(section_concept.average).to eq(0)
      end
    end
  end

  describe '#summative_average' do
    it 'returns the average score for the students' do
      expect(section_concept.summative_average).to eq(average(summative_scores))
    end

    context 'when there are no summative scores for the section' do
      let(:summative_scores) { [] }

      it 'returns 0' do
        expect(section_concept.summative_average).to eq(0)
      end
    end
  end

  describe '#score_change' do
    it 'returns the difference between the summative average and average' do
      expect(section_concept.score_change).to eq(average(summative_scores) - average(scores))
    end
  end
end
