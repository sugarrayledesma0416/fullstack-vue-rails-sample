module StandardsMapping
  describe StandardsMappingIndicesHelper do
    let(:datetime_yr_ago) { (DateTime.now - 1.year) }
    let(:stored_date) { DateTime.now - 1.month }
    let(:initial_config_params) do
      { :upload_type => StandardsMapping::Etl::UploadTypes::INITIAL_UPLOAD_TYPE,
        :index_name => OpenSearchClient.opensearch_stds_index,
        :batch_size => 100,
        :last_upload_date => datetime_yr_ago }
    end
    let(:update_no_last_update_config_params) do
      { :upload_type => StandardsMapping::Etl::UploadTypes::UPDATE_UPLOAD_TYPE,
        :index_name => OpenSearchClient.opensearch_stds_index,
        :batch_size => 100,
        :last_upload_date => datetime_yr_ago }
    end
    let(:update_with_last_update_config_params) do
      { :upload_type => StandardsMapping::Etl::UploadTypes::UPDATE_UPLOAD_TYPE,
        :index_name => OpenSearchClient.opensearch_stds_index,
        :batch_size => 100,
        :last_upload_date => stored_date }
    end
    let(:standards_mapping_helper) { described_class.new(true) }

    before do
      allow(StandardsMapping::Etl::StandardsUploadJob).to receive(:setup)
      allow(StandardsMapping::Etl::StandardAssetsUploadJob).to receive(:setup)
    end

    def kiba_error(index_name)
      ["#{index_name.capitalize} OpenSearch upload caused an error: " \
       "Kiba.run takes either one argument (the job) or a block (defining the job)"]
    end
    describe '#upload_config_params' do
      context 'when the upload type is INITIAL' do
        it 'returns correct config with default date for INITIAL upload' do
          configs = standards_mapping_helper.upload_config_params(
            OpenSearchClient.opensearch_stds_index, StandardsMapping::Etl::UploadTypes::INITIAL_UPLOAD_TYPE
          )
          expect(configs).to include(initial_config_params)
        end
      end

      context 'when there is no stored last upload date for an UPDATE upload' do
        it 'returns correct config with default date' do
          allow(StandardsMappingUploadStatus).to receive(:last_successful_upload_date).with(OpenSearchClient.opensearch_stds_index)
                                             .and_return(nil)
          configs = standards_mapping_helper.upload_config_params(
            OpenSearchClient.opensearch_stds_index, StandardsMapping::Etl::UploadTypes::UPDATE_UPLOAD_TYPE
          )

          expect(configs).to include(update_no_last_update_config_params)
        end
      end

      context 'when there is a stored last upload date for an UPDATE upload' do
        it 'returns correct config with the stored date' do
          allow(StandardsMappingUploadStatus).to receive(:last_successful_upload_date).with(OpenSearchClient.opensearch_stds_index)
                                                                                      .and_return(stored_date)
          configs = standards_mapping_helper.upload_config_params(
            OpenSearchClient.opensearch_stds_index, StandardsMapping::Etl::UploadTypes::UPDATE_UPLOAD_TYPE
          )
          expect(configs).to include(update_with_last_update_config_params)
        end
      end
    end

    describe '#last_upload_date' do
      context 'when there is no last date stored' do
        it 'uses the default of a year ago' do
          allow(StandardsMappingUploadStatus).to receive(:last_successful_upload_date).with(OpenSearchClient.opensearch_stds_index)
                                                                                      .and_return(nil)
          last_upload_date = standards_mapping_helper.last_successful_upload_date(OpenSearchClient.opensearch_stds_index)
          # compare without hours:minutes:seconds
          expect(last_upload_date.to_date).to eq (DateTime.now - 1.year).to_date
        end
      end

      context 'when there is a stored last upload date' do
        it 'uses the stored date' do
          stored_date = DateTime.now - 1.month
          allow(StandardsMappingUploadStatus).to receive(:last_successful_upload_date).with(OpenSearchClient.opensearch_stds_index)
                                                                                      .and_return(stored_date)
          last_upload_date = standards_mapping_helper.last_successful_upload_date(OpenSearchClient.opensearch_stds_index)
          # compare without hours:minutes:seconds
          expect(last_upload_date.to_date).to eq (stored_date).to_date
        end
      end
    end

    describe '#upload_standards' do
      it 'holds no errors if none occurred ' do
        allow(Kiba).to receive(:run).and_return(:true)
        standards_mapping_helper.upload_standards(StandardsMapping::Etl::UploadTypes::UPDATE_UPLOAD_TYPE)
        expect(standards_mapping_helper.errors).to be_empty
      end

      it 'can return its errors if any occurred ' do
        standards_mapping_helper.upload_standards(StandardsMapping::Etl::UploadTypes::UPDATE_UPLOAD_TYPE)
        expect(standards_mapping_helper.errors).to eql(kiba_error(StandardsMapping::OpenSearchClient.opensearch_stds_index))
      end
    end

    describe '#upload_standard_assets' do
      it 'holds no errors if none occurred ' do
        allow(Kiba).to receive(:run).and_return(:true)
        standards_mapping_helper.upload_standard_assets(StandardsMapping::Etl::UploadTypes::UPDATE_UPLOAD_TYPE)
        expect(standards_mapping_helper.errors).to be_empty
      end

      it 'can return its errors if any occurred ' do
        standards_mapping_helper.upload_standard_assets(StandardsMapping::Etl::UploadTypes::UPDATE_UPLOAD_TYPE)
        expect(standards_mapping_helper.errors).to eql(kiba_error(StandardsMapping::OpenSearchClient.opensearch_std_assets_index))
      end
    end

    describe '#delete_standard_alignments' do
      let(:primary_alignment) { instance_double(StandardAlignment, id: 1) }
      let(:secondary_alignment) { instance_double(StandardAlignment, id: 2) }
      let(:open_search_client) { instance_double(StandardsMapping::OpenSearchClient) }

      before do
        allow(standards_mapping_helper).to receive_messages(
          output_msg: nil,
          log_upload_status: nil
        )

        allow(StandardsMapping::OpenSearchClient).to receive_messages(
          new: open_search_client,
          opensearch_std_alignments_index: 'std_alignments_index'
        )
      end

      context 'when obsolete_alignments is blank' do
        it 'logs and returns early' do
          expect(standards_mapping_helper).to receive(:output_msg).with(
            'Deleting obsolete alignments: 0'
          )
          expect(standards_mapping_helper).to receive(:output_msg).with('No obsolete alignments to delete.')
          expect(standards_mapping_helper).not_to receive(:log_upload_status)
          standards_mapping_helper.delete_standard_alignments(obsolete_alignments: [])
        end
      end

      context 'when bulk deletion is successful' do
        it 'calls bulk_upload and logs success' do
          expect(open_search_client).to receive(:bulk_upload).with([
                                                                     { delete: { _index: StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias,
                                                                                 _id: 1 } },
                                                                     { delete: { _index: StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias, _id: 2 } }
                                                                   ])
          expect(standards_mapping_helper).to receive(:output_msg).with("Deleted 2 obsolete alignments.")
          expect(standards_mapping_helper).to receive(:output_msg).with('All obsolete alignments deleted successfully.')
          expect(standards_mapping_helper).to receive(:log_upload_status).with(
            StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias, 'DELETE', true, nil
          )

          standards_mapping_helper.delete_standard_alignments(obsolete_alignments: [primary_alignment,
                                                                                    secondary_alignment])
        end
      end
    end
  end
end
