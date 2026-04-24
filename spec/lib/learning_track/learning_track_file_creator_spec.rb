describe LearningTrack::LearningTrackFileCreator do
  describe '.create' do
    let(:s3_bucket) { double(Radner::S3Storage) }

    before do
      allow(program).to receive(:clone).and_return(program)
      allow(Radner::S3Storage).to receive(:new).and_return(s3_bucket)
      allow(s3_bucket).to receive(:fetch)
      allow(s3_bucket).to receive(:directory_files).and_return([])
      allow(Maestro::CoursePackage).to receive(:all).with(program.id).and_return([double(Maestro::CoursePackage, id: 1)])
    end

    context 'when program is vol' do
      let(:program) { build_stubbed(:program, family: 'vista_online_learning') }
      let(:vol_exporter) do
        double(LearningTrack::VolExporter,
                 group_set_files: [],
                 track_family_spreadsheets: [double('file_description', key: 'Estructura_1.xlsx')],
                 learning_track_files: [double('file_description', key: 'activities_1.xlsx')],
                 delete_track_files: nil,
                 write_activities_json: nil)
      end

      let(:exporter) { double('Exporter', write_categories_json: nil,
                                          write_learning_track_json: nil,
                                          write_activities_json: nil) }

      before do
        allow(LearningTrack::ActivityExporter).to receive(:new).and_return(exporter)
        allow(LearningTrack::VolExporter).to receive(:new).and_return(vol_exporter)
        allow(LearningTrack::GroupSetImporterV2).to receive(:new).and_return(exporter)
        allow(LearningTrack::CategoryExporter).to receive(:new).and_return(exporter)
        allow(LearningTrack::LearningTrackExporter).to receive(:new).and_return(exporter)
      end

      it 'creates learning track file' do
        expect(LearningTrack::VolExporter).to receive(:new).with(program).and_return(vol_exporter)
        expect(vol_exporter).to receive(:write_activities_json)
        described_class.create(program)
      end

      it 'extends all the learning track exporter modules except the ActivityExporter' do
        expect(LearningTrack::ActivityExporter).not_to receive(:new)
        expect(LearningTrack::VolExporter).to receive(:new).with(program).and_return(vol_exporter)
        expect(LearningTrack::GroupSetImporterV2).to receive(:new).with(program).and_return(exporter)
        expect(LearningTrack::CategoryExporter).to receive(:new).with(program).and_return(exporter)
        expect(LearningTrack::LearningTrackExporter).to receive(:new).with(program).and_return(exporter)
        described_class.create(program)
      end
    end
  end
end
