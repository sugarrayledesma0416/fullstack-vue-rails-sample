describe QuestionBankTopicsConcept do
  describe 'validations' do
    context 'uniqueness constraints' do
      it 'prevents the same concept_id and question_bank_topic_id combination' do
        concept = create(:concept)
        question_bank_topic = create(:question_bank_topic)

        create(:question_bank_topics_concept, concept: concept, question_bank_topic: question_bank_topic)
        dup_mapping = build(:question_bank_topics_concept, concept: concept, question_bank_topic: question_bank_topic)
        expect(dup_mapping).not_to be_valid
        expect(dup_mapping.errors[:concept_id]).to include "#{concept.name} with ID #{concept.id} is already mapped to #{question_bank_topic.name}."
      end
    end
  end
end
