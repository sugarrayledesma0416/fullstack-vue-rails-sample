describe StandardAsset do
  describe 'validations' do
    it 'throws a uniqueness error saving if the vendor_guid is not unique' do
      create(:standard_asset, vendor_guid: 'foo')
      expect do
        create(:standard_asset, vendor_guid: 'foo')
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '#create' do
    context 'when given nested attributes for an assessment item' do
      it 'creates an assessment item record also' do
        assessment = create(:activity)
        described_class.create(
          vendor_guid: 'a-guid',
          reference_type: 'AssessmentItem',
          assessment_item_attributes: {
            assessment_id: assessment.cms_activity_id,
            guid: 'abc123',
            points_possible: 50
          }
        )
        expect(AssessmentItem.find_by(guid: 'abc123')).to be_present
      end
    end

    context 'when given nested attributes for an ereader_item' do
      it 'creates an ereader_item record also' do
        concept = create(:concept)
        described_class.create(
          vendor_guid: 'ereader_item_guid',
          reference_type: 'EReaderItem',
          ereader_item_attributes: {
            guid: 'ereader_item_guid',
            concept: concept,
            title: 'Some title',
            descriptor: 'Describes something',
            page_section: 'Explore',
            page_number: 50
          }
        )
        expect(EReaderItem.find_by(guid: 'ereader_item_guid')).to be_present
      end
    end
  end

  describe '.update_published_status' do
    context 'when the published object is an Activity' do
      it 'finds and updates its StandardAsset m3_published_status to true' do
        activity = create(:activity)
        std_asset = create(:standard_asset,
                           reference_id: activity.cms_activity_id,
                           m3_publish_status: false)
        described_class.update_published_status(activity.cms_activity_id)
        expect(std_asset.reload.m3_publish_status).to be_truthy
      end
    end

    context 'when the published object is not found in the Activities table' do
      let(:assessment) { create(:activity, activity_type: 'exam') }
      let!(:ai_standard_asset_1) do
        described_class.create(
          vendor_guid: SecureRandom.uuid,
          reference_type: 'AssessmentItem',
          m3_publish_status: false,
          assessment_item_attributes: {
            assessment_id: assessment.cms_activity_id,
            guid: SecureRandom.uuid,
            points_possible: 20
          }
        )
      end
      let!(:ai_standard_asset_2) do
        described_class.create(
          vendor_guid: SecureRandom.uuid,
          reference_type: 'AssessmentItem',
          m3_publish_status: false,
          assessment_item_attributes: {
            assessment_id: assessment.cms_activity_id,
            guid: SecureRandom.uuid,
            points_possible: 20
          }
        )
      end
      let!(:ai_standard_asset_3) do
        described_class.create(
          vendor_guid: SecureRandom.uuid,
          reference_type: 'AssessmentItem',
          m3_publish_status: false,
          assessment_item_attributes: {
            assessment_id: assessment.cms_activity_id,
            guid: SecureRandom.uuid,
            points_possible: 20
          }
        )
      end

      it 'finds all the StandardAssets that reference the published object\'s cms_activity_id ' \
         'through the related AssessmentItems' do
        described_class.update_published_status(assessment.cms_activity_id)
        expect(ai_standard_asset_1.reload.m3_publish_status).to be_truthy
        expect(ai_standard_asset_2.reload.m3_publish_status).to be_truthy
        expect(ai_standard_asset_3.reload.m3_publish_status).to be_truthy
      end
    end
  end

  describe '#activity_reference?' do
    let(:activity) { create(:activity_with_program) }
    let(:activity_standard_asset) { create(:standard_asset, reference_id: activity.cms_activity_id) }
    let(:ai_standard_asset) { create(:standard_asset_assessment_item, reference_id: activity.cms_activity_id) }
    it 'returns true if standard_asset references an activity' do
      expect(activity_standard_asset.activity_reference?).to be_truthy
    end

    it 'returns false if standard_asset does not reference an activity' do
      expect(ai_standard_asset.activity_reference?).to be_falsey
    end
  end

  describe '#asseessment_item_reference?' do
    let(:assessment) { create(:activity_with_program, activity_type: 'exam') }
    let(:ai_standard_asset) { create(:standard_asset_assessment_item, reference_id: assessment.cms_activity_id) }
    let(:activity_standard_asset) { create(:standard_asset) }
    it 'returns true if standard_asset references an assessment  item' do
      expect(ai_standard_asset.assessment_item_reference?).to be_truthy
    end

    it 'returns false if standard_asset does not reference an assessment item' do
      expect(activity_standard_asset.assessment_item_reference?).to be_falsey
    end
  end

  describe '#ereader_item_reference?' do
    let(:ei_standard_asset) { create(:standard_asset_ereader_item) }
    let(:activity_standard_asset) { create(:standard_asset) }
    it 'returns true if standard_asset references an assessment  item' do
      expect(ei_standard_asset.ereader_item_reference?).to be_truthy
    end

    it 'returns false if standard_asset does not reference an assessment item' do
      expect(activity_standard_asset.ereader_item_reference?).to be_falsey
    end
  end

  describe '#cms_activity_id_for_activity' do
    let(:activity) { create(:activity_with_program) }
    let(:activity_standard_asset) { create(:standard_asset, reference_id: activity.cms_activity_id) }
    let(:ai_standard_asset) { create(:standard_asset_assessment_item) }
    it 'returns cms_activity_id if standard_asset references an activity' do
      expect(activity_standard_asset.cms_activity_id_for_activity).to eql activity.cms_activity_id
    end

    it 'returns nil if standard_asset does not reference an activity' do
      expect(ai_standard_asset.cms_activity_id_for_activity).to be_nil
    end
  end

  describe '#cms_activity_id_for_assessment_item' do
    let(:assessment) { create(:activity_with_program, activity_type: 'exam') }
    let(:ai_standard_asset) { create(:standard_asset_assessment_item) }
    let(:activity_standard_asset) { create(:standard_asset) }
    it 'returns cms_activity_id if standard_asset references an assessment item' do
      expect(ai_standard_asset.cms_activity_id_for_assessment_item).to eql ai_standard_asset.assessment_item.assessment.cms_activity_id
    end

    it 'returns nil if standard_asset does not reference an assessment item' do
      expect(activity_standard_asset.cms_activity_id_for_assessment_item).to be_nil
    end
  end
end
