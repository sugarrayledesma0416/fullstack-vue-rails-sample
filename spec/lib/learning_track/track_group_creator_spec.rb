require 'tasks/learning_track/track_group_creator'

describe LearningTrack::TrackGroupCreator do
  let(:program) { create(:program) }
  let(:lesson) { create(:lesson) }
  let(:concept) { create(:concept) }
  let(:activity) { create(:activity, :lesson => lesson, :concept => concept) }
  let(:activities) { [activity] }
  let(:track_group_creator) { LearningTrack::TrackGroupCreator.new(program.id, activities) }


  describe '#create' do
    context 'when the track group does not exist' do
      it 'creates Learn, Practice, Interact track groups when they do not exist' do
        expect { track_group_creator.create }.to change(TrackGroup, :count).by(3)
      end
    end

    context 'when the track group does exist' do
      it 'does not create the track group' do
        create(:track_group,
                :name => 'Learn',
                :program_id => program.id,
                :lesson_id => lesson.id,
                :concept_id => concept.id)
        expect { track_group_creator.create }.to change(TrackGroup, :count).by(2)
      end
    end
  end
end
