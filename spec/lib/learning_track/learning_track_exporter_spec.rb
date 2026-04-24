describe LearningTrack::LearningTrackExporter do
  let(:program) { create(:program) }
  let(:unit_1) {  create(:unit, program: program, rank: 1) }
  let(:unit_2) {  create(:unit, program: program, rank: 2) }
  let(:concept_1) { create(:concept, base_name: 'Contextos    ') }
  let(:concept_2) { create(:concept, base_name: 'Panorama') }
  let(:concept_3) { create(:concept, base_name: 'Estructura') }
  let(:lesson_1) { create(:lesson, name: 'Bar', unit: unit_1) }
  let(:lesson_2) { create(:lesson, name: 'Bar', unit: unit_2) }
  let(:group_set) { create(:group_set, :name => "Learn Groups") }
  let!(:activity_1) { create(:activity, cms_activity_id: 1, lesson: lesson_1, concept: concept_1, toc_location: 1) }
  let!(:activity_2) { create(:activity, cms_activity_id: 2, lesson: lesson_1, concept: concept_1, toc_location: 1) }
  let!(:activity_3) { create(:activity, cms_activity_id: 3, lesson: lesson_2, concept: concept_2, toc_location: 1) }
  let!(:activity_4) { create(:activity, cms_activity_id: 4, lesson: lesson_1, concept: concept_3, toc_location: 1) }
  let!(:track_group_1) { create(:track_group, :program => program, :name => 'learn', :group_set => group_set, :concept => concept_1, :lesson => lesson_1) }
  let!(:track_group_2) { create(:track_group, :program => program, :name => 'learn', :group_set => group_set, :concept => concept_2, :lesson => lesson_2) }
  let!(:track_group_3) { create(:track_group, :program => program, :name => 'learn', :group_set => group_set, :concept => concept_3, :lesson => lesson_1) }
  let(:filepath) { Rails.root.join('datafiles', Rails.env, 'learning_tracks', "#{program.id}") }
  let(:course_package_ids) { [1, 2, 3] }

  let(:parsed_csv) { CSV.parse(csv_file, col_sep: '|') }
  let(:csv_file) do
    "cms_activity_id|link|lesson|strand|substrand|content_category|title|activity_type|gradebook_category|Enlinea Tracks:Enlinea Track Max|Enlinea Tracks:Enlinea Track Min
1|link1|lesson1|strand1|substrand1|learn|title1|type1|category1|learn|learn
2|link2|lesson2|strand2|substrand2|learn|title2|type2|category2|learn|learn
3|link3|lesson3|strand3|substrand3|learn|title3|type3|category3|learn|
4|link4|lesson4|strand4|substrand4|learn|title4|type4|category3|learn|"
  end

  let(:parsed_track_family) { CSV.parse(track_family_file, col_sep: '|') }
  let(:track_family_file) do
    "Family|Family Description|Track Name|Track Description|Group Set|GB Category Set|Class Types|Family Rank|Subtrack Rank
Enlinea Tracks|Enlinea Description|Enlinea Track Max|Enlinea Track Max Description|Learn Groups|Base Categories|AP,remote,independent study|1|2
||Enlinea Track Min|Enlinea Track Min Description|Learn Groups|Base Categories|slow,remedial||1"
  end

  let(:exporter) { described_class.new(program) } # refactor as a subject
  let(:s3_bucket) { double(Radner::S3Storage) }

  let(:map_hash) do
    {
      'Enlinea Tracks' => {
        subtracks: {
          'Enlinea Track Max' =>
          {
            activities: [
              {
                id: activity_1.id,
                group: 'Learn',
                group_id: track_group_1.id,
                category: 'category1'
              },
              {
                id: activity_2.id,
                group: 'Learn',
                group_id: track_group_1.id,
                category: 'category2'
              },
              {
                id: activity_3.id,
                group: 'Learn',
                group_id: track_group_2.id,
                category: 'category3'
              },
              {
                id: activity_4.id,
                group: 'Learn',
                group_id: track_group_3.id,
                category: 'category3'
              }
            ],
            course_package_ids:,
            description: 'Enlinea Track Max Description',
            strands: ['Contextos', 'Panorama', 'Estructura'],
            first_unit_id: unit_1.id,
            last_unit_id: unit_2.id,
            units: [unit_1, unit_2],
            categories: 'Base Categories',
            class_types: 'AP,remote,independent study',
            rank: 2
          },
          'Enlinea Track Min' => {
            activities: [
              {
                id: activity_1.id,
                group: 'Learn',
                group_id: track_group_1.id,
                category: 'category1'
              },
              {
                id: activity_2.id,
                group: 'Learn',
                group_id: track_group_1.id,
                category: 'category2'
              }
            ],
            course_package_ids:,
            description: 'Enlinea Track Min Description',
            strands: ['Contextos'],
            first_unit_id: unit_1.id,
            last_unit_id: unit_1.id,
            units: [unit_1],
            categories: 'Base Categories',
            class_types: 'slow,remedial',
            rank: 1
          }
        },
        description: 'Enlinea Description',
        rank: 1
      }
    }
  end

  before do
    allow(Program).to receive(:find).and_return(program)

    # mock out what Roo::Spreadsheet parse will return
    allow(Roo::Spreadsheet).to receive(:open) do |csv|
      double('csv_file').tap do |proxy|
        allow(proxy).to receive(:parse) do
          if csv.to_s =~ /csv\.xlsx/
            parsed_csv.drop(1)
          elsif csv.to_s =~ /track_family_file\.xlsx/
            parsed_track_family.drop(1)
          end
        end

        allow(proxy).to receive(:row) do
          if csv.to_s =~ /csv\.xlsx/
            parsed_csv.first
          elsif csv.to_s =~ /track_family_file\.xlsx/
            parsed_track_family.first
          end
        end
      end
    end

    allow(program).to receive(:lessons).and_return([lesson_1, lesson_2])
    allow(lesson_1).to receive(:concepts).and_return([concept_1, concept_2, concept_3])
  end

  describe '#find_group_id' do
    it 'finds the track group id based on the activity and group set' do
      expect(exporter.find_group_id(activity_1, group_set.name, 'learn')).to eq(track_group_1.id)
    end

    it 'raises an exception when the group set is not found' do
      expect { exporter.find_group_id(activity_1, 'Blah', 'learn') }
        .to raise_error(StandardError, 'Group Set with name: Blah not found.')
    end

    it 'creates the track group when the track_group is not found' do
      track_group = build(:track_group, id: 23, name: 'Explore')
      expect(TrackGroup).to receive(:create).and_return(track_group)
      expect(exporter.find_group_id(activity_1, group_set.name, 'blahblah')).to eq(23)
    end
  end

  describe '#write_learning_track_json' do
    before do
      allow(Radner::S3Storage).to receive(:new).and_return(s3_bucket)
      allow(s3_bucket).to receive(:fetch)
      allow(s3_bucket).to receive(:directory_files).and_return([])
    end

    it 'turns a track hash into json' do
      expect(s3_bucket)
        .to receive(:store_file_contents!)
        .with(
          exporter.file_path("Enlinea Tracks(1)_#{program.id}.json"),
          JSON.generate(map_hash.as_json)
        )

      exporter.write_learning_track_json('csv.xlsx', 'track_family_file.xlsx', course_package_ids)
    end
  end
end
