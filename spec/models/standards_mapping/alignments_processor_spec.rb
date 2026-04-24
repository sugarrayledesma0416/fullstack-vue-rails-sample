describe StandardsMapping::AlignmentsProcessor do
  let(:alignments_processor) { described_class.new }
  let(:asset_1) { create(:standard_asset) }
  let(:asset_2) { create(:standard_asset) }
  let!(:activity_1) { create(:activity_with_program) }
  let!(:activity_2) { create(:activity_with_program) }
  let!(:asset_1) { create(:standard_asset, reference_id: activity_1.cms_activity_id) }
  let!(:asset_2) { create(:standard_asset, reference_id: activity_2.cms_activity_id) }
  let!(:asset_3) { create(:standard_asset_assessment_item) }
  let(:alignments_response) { Rails.root.join('spec/fixtures/json/asset_alignments.json').read }
  let(:empty_alignments_response) {
    Rails.root.join('spec/fixtures/json/empty_asset_alignments.json').read
  }
  let(:added_alignments_response) {
    Rails.root.join('spec/fixtures/json/added_asset_alignment.json').read
  }
  let(:removed_alignments_response) {
    Rails.root.join('spec/fixtures/json/removed_asset_alignment.json').read
  }
  let(:standard_guids) do
    JSON.parse(alignments_response)['data'].pluck('id')
  end

  before do
    standard_guids.each do |guid|
      create(:standard, vendor_guid: guid)
    end
    assessment = Activity.where(cms_activity_id: asset_3.assessment_item.assessment_id).first
    assessment.lesson.unit.program = activity_1.lesson.unit.program
    assessment.lesson.unit.save!
  end

  describe '#import_new_assets' do
    it 'imports all alignments for new assets' do
      allow(alignments_processor.ab_client).to(
        receive(:fetch_asset_alignments)
        .with(guid: asset_1.vendor_guid, offset: 0, limit: 100)
        .and_return(JSON.parse(alignments_response))
      )
      allow(alignments_processor.ab_client).to(
        receive(:fetch_asset_alignments)
          .with(guid: asset_2.vendor_guid, offset: 0, limit: 100)
          .and_return(JSON.parse(alignments_response))
      )
      allow(alignments_processor.ab_client).to(
        receive(:fetch_asset_alignments)
          .with(guid: asset_3.vendor_guid, offset: 0, limit: 100)
          .and_return(JSON.parse(alignments_response))
      )
      alignments_processor.import_new_assets
      expect(StandardAlignment.count).to eq 9
      expect(asset_1.reload.date_alignments_modified_utc.to_date).to eq Time.zone.today
      expect(asset_2.reload.date_alignments_modified_utc.to_date).to eq Time.zone.today
      expect(asset_3.reload.date_alignments_modified_utc.to_date).to eq Time.zone.today
    end

    it 'returns failure message when save process was not successful' do
      allow(Rails.logger).to receive(:error)

      # Stub `find_by` to return nil to simulate that no alignment exists
      # Stub `.new` to return a double that raises an error on `save!`
      mock_alignment = instance_double(StandardAlignment)
      allow(StandardAlignment).to receive(:find_by).and_return(nil)
      allow(StandardAlignment).to receive_messages(
        find_by: nil,
        new: mock_alignment
      )

      allow(mock_alignment).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved)

      allow(alignments_processor.ab_client).to(
        receive(:fetch_asset_alignments)
          .with(guid: asset_1.vendor_guid, limit: 100, offset: 0)
          .and_return(JSON.parse(alignments_response))
      )
      allow(alignments_processor.ab_client).to(
        receive(:fetch_asset_alignments)
          .with(guid: asset_2.vendor_guid, limit: 100, offset: 0)
          .and_return(JSON.parse(alignments_response))
      )
      allow(alignments_processor.ab_client).to(
        receive(:fetch_asset_alignments)
          .with(guid: asset_3.vendor_guid, limit: 100, offset: 0)
          .and_return(JSON.parse(alignments_response))
      )

      alignments_processor.import_new_assets

      expected_error_msg = "Alignments for asset with id: #{asset_1.id} could not be processed."

      expect(Rails.logger).to have_received(:error).at_least(:once).with(a_string_including(expected_error_msg))
    end
  end

  describe '#import_updated_alignments' do
    before do
      allow(alignments_processor.ab_client).to(
        receive(:fetch_asset_alignments)
        .with(guid: asset_1.vendor_guid, offset: 0, limit: 100)
        .and_return(JSON.parse(alignments_response))
      )
      allow(alignments_processor.ab_client).to(
        receive(:fetch_asset_alignments)
          .with(guid: asset_2.vendor_guid, offset: 0, limit: 100)
          .and_return(JSON.parse(alignments_response))
      )
      allow(alignments_processor.ab_client).to(
        receive(:fetch_asset_alignments)
          .with(guid: asset_3.vendor_guid, offset: 0, limit: 100)
          .and_return(JSON.parse(alignments_response))
      )

      alignments_processor.import_new_assets
      asset_1.date_alignments_modified_utc = DateTime.now - 1.day
      asset_1.save
      asset_1.reload
      asset_2.date_alignments_modified_utc = DateTime.now - 1.day
      asset_2.save
      asset_2.reload
      asset_3.date_alignments_modified_utc = DateTime.now - 1.day
      asset_3.save
      asset_3.reload
    end

    it 'imports any new alignments for existing assets' do
      create(:standard, vendor_guid: JSON.parse(added_alignments_response)['data'].first['id'])

      allow(alignments_processor.ab_client).to(
        receive(:fetch_asset_alignments)
          .with(guid: asset_1.vendor_guid,
                date_created_utc: asset_1.date_alignments_modified_utc,
                offset: 0,
                limit: 100)
          .and_return(JSON.parse(added_alignments_response))
      )
      allow(alignments_processor.ab_client).to(
        receive(:fetch_asset_alignments)
          .with(guid: asset_1.vendor_guid,
                date_deleted_utc: asset_1.date_alignments_modified_utc,
                offset: 0,
                limit: 100)
          .and_return(JSON.parse(empty_alignments_response))
      )
      allow(alignments_processor.ab_client).to(
        receive(:fetch_asset_alignments)
          .with(guid: asset_3.vendor_guid,
                date_created_utc: asset_3.date_alignments_modified_utc,
                offset: 0,
                limit: 100)
          .and_return(JSON.parse(added_alignments_response))
      )
      allow(alignments_processor.ab_client).to(
        receive(:fetch_asset_alignments)
          .with(guid: asset_3.vendor_guid,
                date_deleted_utc: asset_3.date_alignments_modified_utc,
                offset: 0,
                limit: 100)
          .and_return(JSON.parse(empty_alignments_response))
      )

      alignments_processor.import_updated_alignments(activity_1.lesson.unit.program.id)

      expect(StandardAlignment.count).to eq 11
      expect(asset_1.reload.date_alignments_modified_utc.to_date).to eq Time.zone.now.to_date
      expect(asset_3.reload.date_alignments_modified_utc.to_date).to eq Time.zone.now.to_date
    end

    it 'deletes any alignments removed in the AB UI for an existing asset' do
      allow(alignments_processor.ab_client).to(
        receive(:fetch_asset_alignments)
        .with(guid: asset_1.vendor_guid,
              date_created_utc: asset_1.date_alignments_modified_utc,
              offset: 0,
              limit: 100)
        .and_return(JSON.parse(empty_alignments_response))
      )
      allow(alignments_processor.ab_client).to(
        receive(:fetch_asset_alignments)
        .with(guid: asset_1.vendor_guid,
              date_deleted_utc: asset_1.date_alignments_modified_utc,
              offset: 0,
              limit: 100)
        .and_return(JSON.parse(removed_alignments_response))
      )
      allow(alignments_processor.ab_client).to(
        receive(:fetch_asset_alignments)
          .with(guid: asset_3.vendor_guid,
                date_created_utc: asset_3.date_alignments_modified_utc,
                offset: 0,
                limit: 100)
          .and_return(JSON.parse(empty_alignments_response))
      )
      allow(alignments_processor.ab_client).to(
        receive(:fetch_asset_alignments)
          .with(guid: asset_3.vendor_guid,
                date_deleted_utc: asset_3.date_alignments_modified_utc,
                offset: 0,
                limit: 100)
          .and_return(JSON.parse(removed_alignments_response))
      )
      alignments_processor.import_updated_alignments(activity_1.lesson.unit.program.id)

      expect(StandardAlignment.count).to eq 7
      expect(asset_1.reload.date_alignments_modified_utc.to_date).to eq Time.zone.now.to_date
      expect(asset_3.reload.date_alignments_modified_utc.to_date).to eq Time.zone.now.to_date
    end
  end

  describe '#sync_asset_alignments' do
    let(:helper) { instance_double(StandardsMapping::StandardsMappingIndicesHelper) }
    let(:last_sync_date) { 2.days.ago }
    let!(:asset_recent) { create(:standard_asset, date_alignments_modified_utc: 1.day.ago) }
    let!(:asset_old) { create(:standard_asset, date_alignments_modified_utc: 3.days.ago) }

    before do
      allow(StandardsMapping::StandardsMappingIndicesHelper).to receive(:new).and_return(helper)
      allow(helper).to receive(:last_successful_upload_date).and_return(last_sync_date)
      allow(StandardsMapping::OpenSearchClient).to receive(
        :opensearch_std_alignments_alias
      ).and_return('index_name')

      # Spy on processor methods
      allow(alignments_processor).to receive(:process_new_alignments)
      allow(alignments_processor).to receive(:remove_obsolete_alignments)
      allow(Rails.logger).to receive(:info)
    end

    it 'processes only assets modified since last sync' do
      alignments_processor.sync_asset_alignments

      expect(alignments_processor).to have_received(:process_new_alignments).with(asset_recent)
      expect(alignments_processor).to have_received(:remove_obsolete_alignments).with(asset_recent)
      expect(alignments_processor).not_to have_received(:process_new_alignments).with(asset_old)
      expect(alignments_processor).not_to have_received(:remove_obsolete_alignments).with(asset_old)
    end

    it 'logs a success message for each processed asset' do
      alignments_processor.sync_asset_alignments
      expect(Rails.logger).to have_received(:info).with(a_string_including("Alignments for asset with id: #{asset_recent.id} were processed successfully."))
    end
  end
end
