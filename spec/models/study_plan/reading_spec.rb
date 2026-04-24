describe StudyPlan::Reading do
  let(:user) { create(:user) }
  let(:program) { create(:program) }
  let(:unit) { create(:unit, program: program) }
  let(:section) { create(:section) }

  let(:recommendation_params) do
    {
      user_id: user.id,
      section_id: section.id,
      program_id: program.id,
      unit_id: unit.id,
      has_vocab_access: true
    }
  end

  let(:recommendation) { create(:recommendation) }
  let(:concept_reading) { described_class.new(recommendation, recommendation_params) }

  before do
    create(:user_reading, recommendation: recommendation, user_id: user.id)
  end

  describe '#path' do
    it 'returns the referenced activity path' do
      expect(concept_reading.path).to eq "/sections/#{section.id}/activities/"\
        "#{recommendation.cms_activity_id}/popup?program_id=#{program.id}"
    end

    context "when recommendation is of type 'vocabulary'" do
      it "returns the path to the lesson's vocabulary page" do
        allow(recommendation).to receive(:recommendation_type)
          .and_return('vocabulary')
        expect(concept_reading.path).to eq(
          "/#{program.id}/sections/#{section.id}/vocab_tools/words?unit_id=#{unit.id}"
        )
      end
    end
  end

  describe '#viewable?' do
    context 'when recommendation is not of type "vocabulary"' do
      it 'returns true' do
        expect(concept_reading).to be_viewable
      end
    end

    context 'when recommendation is of type "vocabulary"' do
      before do
        allow(recommendation).to receive(:recommendation_type)
          .and_return('vocabulary')
      end

      context 'when user has access to vocab tools' do
        it 'returns true' do
          expect(concept_reading).to be_viewable
        end
      end

      context 'when user does not have access to vocab tools' do
        it 'returns false' do
          recommendation_params[:has_vocab_access] = false
          expect(concept_reading).not_to be_viewable
        end
      end
    end
  end

  describe '#html_class_name' do
    context 'when reading has been viewed' do
      it 'returns an empty string' do
        UserReading.last.update(viewed: true)
        expect(concept_reading.html_class_name).to eq('')
      end
    end

    context 'when reading has not been viewed' do
      it '"is-diabled"' do
        expect(concept_reading.html_class_name).to eq('is-disabled')
      end
    end
  end
end
