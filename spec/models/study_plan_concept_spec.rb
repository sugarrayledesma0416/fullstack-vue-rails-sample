describe StudyPlanConcept do
  let(:concept) { create(:study_plan_concept) }

  describe '#sorted_recommendations' do
    context 'when there is not a vocabulary recommendation' do
      it 'does not sort recommendations' do
        create(:recommendation, study_plan_concept: concept)
        create(:supplemental_recommendation, study_plan_concept: concept)
        first_recommendation = concept.sorted_recommendations.first
        expect(first_recommendation.recommendation_type).to eq 'reference'
      end
    end

    context 'when there is a vocabulary recommendation' do
      context 'when the first recommendation is of type vocabulary' do
        it 'does not sort recommendations' do
          create(:vocabulary_recommendation, study_plan_concept: concept)
          create(:recommendation, study_plan_concept: concept)
          first_recommendation = concept.sorted_recommendations.first
          expect(first_recommendation.recommendation_type).to eq 'vocabulary'
        end
      end

      context 'when the first recommendation is not of type vocabulary' do
        it 'returns vocabulary recommendation as the first recommendation' do
          create(:recommendation, study_plan_concept: concept)
          create(:vocabulary_recommendation, study_plan_concept: concept)
          first_recommendation = concept.sorted_recommendations.first
          expect(first_recommendation.recommendation_type).to eq 'vocabulary'
        end
      end
    end
  end

  describe '#diagnostic_concept' do
    let(:activity) { create(:activity) }

    context 'when the content_object class does not respond to concepts' do
      let(:fake_content_class) { Class.new }

      it 'returns nil' do
        allow(activity).to receive(:content_object).and_return(fake_content_class)
        expect(concept.diagnostic_concept).to eq(nil)
      end
    end

    context 'when the content_object class responds to concepts' do
      let(:diagnostic_v2_xml) { File.open('spec/fixtures/xml/diagnostic_v2.xml') }
      let(:doc) { Nokogiri::XML.parse(diagnostic_v2_xml) }
      let(:linked_media_item) { LinkedMediaItemStub }
      let(:content_object) do
        MaestroActivityEngine::ActivityParser.create_parser(doc.to_s, linked_media_item).parse
      end

      let(:concept) { create(:study_plan_concept, activity: activity, reference_id: '1') }

      it 'returns the appropriate diagnostic concept' do
        allow(activity).to receive(:content_object).and_return(content_object)

        expect(concept.diagnostic_concept.ref).to eq('1')
      end
    end
  end
end
