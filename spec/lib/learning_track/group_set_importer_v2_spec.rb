describe LearningTrack::GroupSetImporterV2 do
  let(:program) { create(:program, :id => 48) }
  let!(:unit_1) { create(:unit, :program => program, :lessons => [lesson_1]) }
  let!(:unit_2) { create(:unit, :program => program, :lessons => [lesson_2, lesson_12]) }
  let(:lesson_1) { create(:lesson, :id => 100, :label => 'Lesson 1') }
  let(:lesson_2) { create(:lesson, :id => 200, :label => 'Lesson 2') }
  let(:lesson_12) { create(:lesson, :id => 1200, :label => 'Lesson 12') }

  let(:file_name) { 'group_set.xlsx' }
  let(:parsed_file) { CSV.parse(file) }
  let(:file) do
    "Group Set,Learn groups,,
Lesson,Strand,Group,Learning Objective,How To Use
1,Contextos,Explore,objective 1,how to use 1
1,Contextos,Learn,objective 2,how to use 2
1,Fotonovela,Explore,objective 3,how to use 3
2,Contextos,Learn,objective 4,how to use 4
12,Estructura     1.1,Learn,objective 5,how to use 5"
  end

  let(:importer) { LearningTrack::GroupSetImporterV2.new(program) }
  let(:s3_bucket) { double(Radner::S3Storage) }
  let(:xlsx) { double(Roo::Excelx) }
  let(:csv_data) do
    [
      {
        'lesson_id' => 100,
        'concept_id' => 1,
        'name' => 'Explore',
        'objective' => 'objective 1',
        'how_to_use' => 'how to use 1'
      },
      {
        'lesson_id' => 100,
        'concept_id' => 1,
        'name' => 'Learn',
        'objective' => 'objective 2',
        'how_to_use' => 'how to use 2'
      },
      {
        'lesson_id' => 100,
        'concept_id' => 2,
        'name' => 'Explore',
        'objective' => 'objective 3',
        'how_to_use' => 'how to use 3'
      },
      {
        'lesson_id' => 200,
        'concept_id' => 3,
        'name' => 'Learn',
        'objective' => 'objective 4',
        'how_to_use' => 'how to use 4'
      },
      {
        'lesson_id' => 1200,
        'concept_id' => 4,
        'name' => 'Learn',
        'objective' => 'objective 5',
        'how_to_use' => 'how to use 5'
      }
    ]
  end

  before do
    create(:concept, id: 1, name: 'Contextos', lesson: lesson_1)
    create(:concept, id: 2, name: 'Fotonovela', lesson: lesson_1)
    create(:concept, id: 3, name: 'Contextos', lesson: lesson_2)
    create(:concept, id: 4, name: 'Estructura: 1.1', lesson: lesson_12)

    allow(Roo::Spreadsheet).to receive(:open).and_return(xlsx)
    allow(xlsx).to receive(:parse).with({}).and_return(parsed_file.drop(1))
    allow(xlsx).to receive(:row).with(1).and_return(parsed_file.first)

    allow(Radner::S3Storage).to receive(:new).and_return(s3_bucket)
    allow(s3_bucket).to receive(:fetch)
  end

  describe '#build_track_groups_from_csv' do
    it 'returns an array of hashes representing track groups' do
      importer.import(file_name)
      expect(importer.build_track_groups_from_csv).to eq(csv_data)
    end
  end

  describe '#create_group_set' do
    before do
      importer.csv = CSV.parse(file)
      importer.group_set_name = importer.csv.shift.compact.last
    end

    context 'when the group set does not exist' do
      it 'creates the group set with the correct name' do
        expect { importer.create_group_set }.to change(GroupSet, :count).by(1)
        expect(GroupSet.where(:name => 'Learn groups').count).to eq(1)
      end
    end

    context 'when the group set does exist' do
      it 'does not create the group set' do
        create(:group_set, :name => 'Learn groups')
        expect { importer.create_group_set }.to change(GroupSet, :count).by(0)
        expect(GroupSet.where(:name => 'Learn groups').count).to eq(1)
      end
    end
  end

  describe '#import' do
    context 'when the track groups do not exist' do
      it 'creates the track groups' do
        expect { importer.import(file_name) }.to change(TrackGroup, :count).by(5)
      end
    end

    context 'when track groups do exist' do
      it 'does not create the track groups' do
        group_set = create(:group_set, name: CSV.parse(file).shift.compact.last)
        create(:track_group,
                :name => 'Explore',
                :program_id => 48,
                :lesson_id => '100',
                :concept_id => '1',
                :group_set_id => group_set.id)
        expect { importer.import(file_name) }.to change(TrackGroup, :count).by(4)
      end
    end
  end
end
