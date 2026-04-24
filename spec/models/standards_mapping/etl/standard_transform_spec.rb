module StandardsMapping
  module Etl
    describe 'StandardTransform' do
      let(:standard) { create(:standard) }
      let(:update_standard) { create(:standard) }
      let(:converted_std) do
        {
          standard_id: standard.id,
          standard_guid: standard.vendor_guid,
          standard_name: standard.name,
          standard_number: standard.number,
          standard_label: standard.label,
          standard_description: standard.description
        }
      end
      let(:expected_result) do
        [
          {
            index: {
              _index: "#{OpenSearchClient.index_prefix}standards",
              _id: standard.id
            }
          },
          converted_std
        ]
      end
      let(:expected_update_result) do
        [
          {
            update: {
              _index: "#{OpenSearchClient.index_prefix}standards",
              _id: standard.id
            }
          },
          {
            doc: converted_std
          }
        ]
      end

      def config_params(upload_type, last_upload_date)
        {
          upload_type: upload_type,
          last_upload_date: last_upload_date
        }
      end

      before do
        converter = StandardConverter.new
        allow(converter).to receive(:convert).and_return(converted_std)
        allow(StandardConverter).to receive(:new).and_return(converter)
      end

      describe '#process' do
        context 'when transforming a Standard to the format required for upload to OpenSearch' do
          it 'transforms a Standard for initial upload' do
            transformer = StandardTransform.new(config_params(StandardsMapping::Etl::UploadTypes::INITIAL_UPLOAD_TYPE, nil))
            expect(transformer.process(standard)).to eql expected_result
          end

          it 'transforms a new Standard for update upload' do
            standard.created_at = DateTime.now - 2.months
            standard.save
            transformer = StandardTransform.new(config_params(StandardsMapping::Etl::UploadTypes::UPLOAD_TYPES, DateTime.now - 3.months))
            expect(transformer.process(standard)).to eql expected_result
          end

          it 'transforms a modified Standard for update upload' do
            standard.created_at = DateTime.now - 2.months
            standard.updated_at = DateTime.now - 15.days
            standard.save
            transformer = StandardTransform.new(config_params(StandardsMapping::Etl::UploadTypes::UPLOAD_TYPES, DateTime.now - 1.months))
            expect(transformer.process(standard)).to eql expected_update_result
          end
        end
      end
    end
  end
end
