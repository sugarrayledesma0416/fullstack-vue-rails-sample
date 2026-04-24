module StandardsMapping
  describe StandardAssetCsvGenerator do
    describe '#generate_csv_string' do
      let(:program_id) { 1 }
      let(:asset_type) { 'activity' }
      let(:exporter_double) { instance_double(StandardsMapping::StandardAssetExporter) }
      let(:asset_data) do
        [
          {
            'guid' => 'TE-123',
            'client_id' => 'TE-789',
            'title' => 'E-Book Chapter',
            'domain' => 'Literature',
            'subdomain' => 'Poetry',
            'program_ids' => '1',
            'mapped_item_type' => 'TEContent',
            'unit_name' => 'Intro Unit Level A',
            'lesson_name' => 'Intro Unit Level A',
            'strand_name' => 'Proficiency Assessment',
            'component_name' => 'Assessment',
            'activity_type' => 'exam',
            'content_url' => 'https://cms.vhlcentral.com/activities/297182',
            'm3_url' => 'https://m3a.vhlcentral.com/sections/0/activities/297182?activate_guid_viewer=true',
            'standards_id_list' => 'STAND-001,STAND-002'
          }
        ]
      end

      before do
        allow(exporter_double).to receive(:each).and_yield(asset_data.first)
        allow(exporter_double).to receive(:to_a).and_return(asset_data)
        allow(StandardsMapping::StandardAssetExporter).to receive(:new).with(
          program_id,
          asset_type
        ).and_return(exporter_double)
      end

      subject(:csv_generator) { described_class.new(program_id, asset_type) }

      it 'generates a CSV string with the correct headers' do
        csv_output = csv_generator.generate_csv_string
        parsed_csv = CSV.parse(csv_output, headers: true)

        expect(parsed_csv.headers).to eq(StandardAssetCsvGenerator::ACTIVITY_HEADERS)
      end

      it 'generates a CSV string with the correct row data' do
        csv_output = csv_generator.generate_csv_string
        parsed_csv = CSV.parse(csv_output, headers: true)

        expect(parsed_csv.map(&:to_h)).to eq(asset_data)
      end
    end
  end
end
