require 'tasks/learning_track/group_set_importer'

describe LearningTrack::GroupSetImporter do
  let(:program) { create(:program) }
  let(:unit_1) { create(:unit, program: program) }
  let(:unit_2) { create(:unit, program: program) }
  let(:strand_1) { create(:toc_entry) }
  let(:strand_2) { create(:toc_entry) }
  let(:strand_3) { create(:toc_entry) }
  let(:lesson_1) { create(:lesson, unit: unit_1, toc_entries: [strand_1, strand_2]) }
  let(:lesson_2) { create(:lesson, unit: unit_2, toc_entries: [strand_3]) }
  let(:file) do
    "Group Set,Learn groups,,,,,\n" \
    "Lesson,Strand,Lesson Id,Strand Id,Group,Learning Objective,How To Use\n" \
    "1,Contextos,#{lesson_1.id},#{strand_1.location},Explore,objective 1,how to use 1\n" \
    "1,Contextos,#{lesson_1.id},#{strand_1.location},Learn,objective 2,how to use 2\n" \
    "1,Fotonovela,#{lesson_1.id},#{strand_2.location},Explore,objective 3,how to use 3\n" \
    "2,Contextos,#{lesson_2.id},#{strand_3.location},Learn,objective 4,how to use 4\n"
  end

  let(:importer) { described_class.new(file, program.id) }
  let(:csv_data) do
    [
      {
        'lesson_id' => lesson_1.id.to_s,
        'concept_id' => strand_1.location,
        'name' => 'Explore',
        'objective' => 'objective 1',
        'how_to_use' => 'how to use 1'
      },
      {
        'lesson_id' => lesson_1.id.to_s,
        'concept_id' => strand_1.location,
        'name' => 'Learn',
        'objective' => 'objective 2',
        'how_to_use' => 'how to use 2'
      },
      {
        'lesson_id' => lesson_1.id.to_s,
        'concept_id' => strand_2.location,
        'name' => 'Explore',
        'objective' => 'objective 3',
        'how_to_use' => 'how to use 3'
      },
      {
        'lesson_id' => lesson_2.id.to_s,
        'concept_id' => strand_3.location,
        'name' => 'Learn',
        'objective' => 'objective 4',
        'how_to_use' => 'how to use 4'
      }
    ]
  end

  before do
    create(:concept, id: strand_1.location, name: 'Contextos', lesson: lesson_1)
    create(:concept, id: strand_2.location, name: 'Fotonovela', lesson: lesson_1)
    create(:concept, id: strand_3.location, name: 'Contextos', lesson: lesson_2)
    spreadsheet = instance_double(Roo::CSV, parse: CSV.parse(file))
    allow(Roo::Spreadsheet).to receive(:open).and_return(spreadsheet)
  end

  describe '#build_track_groups_from_csv' do
    it 'returns an array of hashes representing track groups' do
      expect(importer.build_track_groups_from_csv).to eq(csv_data)
    end
  end

  describe '#create_group_set' do
    context 'when the group set does not exist' do
      it 'creates the group set with the correct name' do
        expect { importer.create_group_set }.to change(GroupSet, :count).by(1)
        expect(GroupSet.where(name: 'Learn groups').count).to eq(1)
      end
    end

    context 'when the group set does exist' do
      it 'does not create the group set' do
        create(:group_set, name: 'Learn groups')
        expect { importer.create_group_set }.to change(GroupSet, :count).by(0)
        expect(GroupSet.where(name: 'Learn groups').count).to eq(1)
      end
    end
  end

  describe '#import' do
    context 'when the track groups do not exist' do
      it 'creates the track groups' do
        expect { importer.import }.to change(TrackGroup, :count).by(4)
      end
    end

    context 'when track groups do exist' do
      it 'does not create the track groups' do
        group_set = importer.create_group_set
        create(
          :track_group,
          name: 'Explore',
          program_id: program.id,
          lesson_id: lesson_1.id,
          concept_id: strand_1.location,
          group_set_id: group_set.id
        )
        expect { importer.import }.to change(TrackGroup, :count).by(3)
      end
    end
  end
end
