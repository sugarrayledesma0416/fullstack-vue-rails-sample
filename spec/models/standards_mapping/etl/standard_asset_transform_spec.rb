module StandardsMapping
  module Etl
    describe 'StandardAssetTransform' do
      let(:standard_asset) { create(:standard_asset, date_alignments_modified_utc: Time.zone.now - 1.day) }
      let(:converted_asset) do
        {
          :standard_assets_id=> standard_asset.id,
          :reference_type=> "Activity",
          :programs=>[],
          :standard_alignments=> []
        }
      end
      def config_params(upload_type, last_upload_date)
        {
          upload_type: upload_type,
          last_upload_date: last_upload_date
        }
      end

      before do
        converter = StandardAssetConverter.new
        allow(converter).to receive(:convert).and_return(converted_asset)
        allow(StandardAssetConverter).to receive(:new).and_return(converter)
      end

      describe '#process' do
        let(:expected_result) do
          [
            {
              index: {
                _index: "#{OpenSearchClient.index_prefix}standard_assets", _id: standard_asset.id
              }
            }, converted_asset
          ]
        end


        let(:expected_update_result) do
          [
            {
              update: {
                _index: "#{OpenSearchClient.index_prefix}standard_assets", _id: standard_asset.id
              }
            },
            {
              doc: converted_asset
            }
          ]
        end
        context 'when transforming a StandardAsset to the format required for upload to OpenSearch' do
          it 'transforms a StandardAsset and its alignments  for initial upload' do
            transformer = StandardAssetTransform.new(config_params('INITIAL', nil))
            expect(transformer.process(standard_asset)).to eql expected_result
          end

          it 'transforms a new StandardAsset for update upload' do
            standard_asset.created_at = DateTime.now - 2.months
            standard_asset.save
            transformer = StandardAssetTransform.new(config_params(StandardsMapping::Etl::UploadTypes::UPLOAD_TYPES, DateTime.now - 3.months))
            expect(transformer.process(standard_asset)).to eql expected_result
          end

          it 'transforms a modified StandardAsset for update upload' do
            standard_asset.created_at = DateTime.now - 2.months
            standard_asset.updated_at = DateTime.now - 15.days
            standard_asset.save
            transformer = StandardAssetTransform.new(config_params(StandardsMapping::Etl::UploadTypes::UPLOAD_TYPES, DateTime.now - 1.months))
            expect(transformer.process(standard_asset)).to eql expected_update_result
          end

          it 'transforms a StandardAsset with modified alignments for update upload' do
            standard_asset.created_at = DateTime.now - 2.months
            standard_asset.updated_at = DateTime.now - 2.months
            standard_asset.date_alignments_modified_utc = DateTime.now - 15.days
            standard_asset.save
            transformer = StandardAssetTransform.new(config_params(StandardsMapping::Etl::UploadTypes::UPLOAD_TYPES, DateTime.now - 1.months))
            expect(transformer.process(standard_asset)).to eql expected_update_result
          end
        end
      end
    end
  end
end
