describe QuestionBankTopic do
  let(:question_bank_topic_one) { create(:question_bank_topic) }
  let(:question_bank_topic_two) { create(:question_bank_topic) }

  let(:concept) { create(:concept) }
  let!(:question_bank_topics_concept) { create(:question_bank_topics_concept,
                                               concept: concept,
                                               question_bank_topic: question_bank_topic_one) }

  describe '#has_topic_concepts?' do
    it 'returns true if there is at least one question bank topics concept' do
      expect(question_bank_topic_one.has_topic_concepts?).to be true
    end

    it 'returns false if there is not any question bank topics concept' do
      expect(question_bank_topic_two.has_topic_concepts?).to be false
    end
  end
end
