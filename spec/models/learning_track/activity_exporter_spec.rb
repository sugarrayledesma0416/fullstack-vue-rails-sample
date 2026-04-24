describe LearningTrack::ActivityExporter do
  include RspecJsContentHelpers
  let(:program) { create(:program) }
  let!(:unit_1) {  create(:unit, program: program) }
  let!(:lesson) { create(:lesson, name: 'Bar', unit: unit_1) }
  let!(:concept_1) { create(:concept, :lesson => lesson, name: "Blah", base_name: "Panorama") }
  let!(:concept_2) { create(:concept, :lesson => lesson, name: "Contextos", base_name: "Contextos") }
  let(:toc_entry_1) { create(:two_layers_of_toc_entry) }
  let(:activity) { create(:activity,
                           minutes_to_complete: 10,
                           concept: concept_1,
                           lesson: lesson,
                           activity_type: "audio_hotspots",
                           grading_method: "auto",
                           points_possible: 60) }
  let(:exporter) { LearningTrack::ActivityExporter.new(program) }

  let(:activity_requirements) do
    {
      require_microphone: activity.chat_or_recording?,
      require_partner: activity.partner_chat?,
      instructor_graded: activity.instructor_graded?
    }
  end
  let(:activity_hash) do
    {
      activity.id => {
        id: activity.id,
        title: activity.title,
        unit_id: unit_1.id,
        lesson_name: activity.lesson.name,
        strand_name: 'Blah',
        minutes_to_complete: activity.minutes_to_complete,
        strand: activity.concept.base_name,
        substrand: activity.sub_strand.title,
        activity_requirements: activity_requirements,
        activity_type: Activity.humanize_activity_type(activity.activity_type)
      }
    }
  end

  let(:strands_hash) do
    {
      concept_1.base_name => {
        name: concept_1.base_name,
        color: concept_1.background_color,
        unit_ids: [unit_1.id]
      },
      concept_2.base_name => {
        name: concept_2.base_name,
        color: concept_2.background_color,
        unit_ids: [unit_1.id]
      }
    }
  end

  before do
    allow(Program).to receive(:find).and_return(program)
    allow(program).to receive(:lessons).and_return([lesson])
    allow(lesson).to receive(:substrand_for_toc_location).and_return(toc_entry_1.children.first)
  end

  describe '#get_activity_requirements' do
    it 'returns a hash of an activity\'s requirements' do
      activity_requirements = exporter.get_activity_requirements(activity)
      expect(activity_requirements).to include( :require_microphone,
                                            :require_partner,
                                            :instructor_graded)
    end

    it 'sets the correct values for requirements per activity type' do
      activity.activity_type = 'partner_chat'
      activity_requirements = exporter.get_activity_requirements(activity)
      expect(activity_requirements).to eq({  :require_microphone => true,
                                         :require_partner => true,
                                         :instructor_graded => true })
      activity.activity_type = 'virtual_chat'
      activity_requirements = exporter.get_activity_requirements(activity)
      expect(activity_requirements).to eq({  :require_microphone => true,
                                         :require_partner => false,
                                         :instructor_graded => true })

      comp_activity = build_activity('../fixtures/xml/composition.xml')
      comp_activity.activity_type = 'composition'
      activity_requirements = exporter.get_activity_requirements(comp_activity)
      expect(activity_requirements).to eq({  :require_microphone => false,
                                         :require_partner => false,
                                         :instructor_graded => true })

      comp_activity.activity_type = 'not instructor gradable'
      activity_requirements = exporter.get_activity_requirements(comp_activity)
      expect(activity_requirements).to eq({  :require_microphone => false,
                                         :require_partner => false,
                                         :instructor_graded => false })
    end
  end

  describe 'json' do
    before do
      allow(program).to receive(:activities_with_toc_location).and_return([activity])
    end

    describe '#build_activities_json' do
      it 'returns a hash of activity data' do
        expect(exporter.build_activities_json).to eq(activity_hash)
      end
    end

    describe '#build_strands_json' do
      it 'returns a hash of all the strands and substrands associated with the program' do
        expect(exporter.build_strands_json).to eq(strands_hash)
      end
    end

    describe '#new_activities_hash' do
      it 'returns a hash of map and activity data' do
        expect(exporter.new_activities_hash).to eq({
          'activities' => activity_hash,
          'strands' => strands_hash,
          'tracks' => {}
        })
      end
    end

    describe '#new_activities_json' do
      it 'returns a JSON encoded string of map and activity data' do
        expect(exporter.new_activities_json).to eq(JSON.generate({
          activities: activity_hash,
          strands: strands_hash,
          tracks: {}
        }.as_json))
      end
    end
  end
end
