include RspecJsContentHelpers
module StandardsMapping
  describe ActivitySet do
    let(:program) { create(:program_with_toc_entries) }
    let(:program_2) { create(:program_with_toc_entries) }

    ## Items expected to be found:
    # Activities in selected program
    let!(:activity_1) { create_true_false_enhanced_activity(program) }
    let!(:activity_2) { create_cumulative_matching_activity(program) }

    # Unlisted activity (see before block)
    let!(:activity_unlisted) { create_cumulative_matching_activity(program) }

    ## Items not expected to be found:
    
    # IGC from the selected program
    let!(:activity_igc) do
      # doesn't save without cms_revision_id unless has an object to check for IGC type
      igc = build(
        :instructor_generated_activity,
        instructor_id: 1,
        lesson: activity_1.lesson,
        concept: activity_1.concept
      )
      allow(igc).to receive(:is_a?).and_return(true)
      allow(igc).to receive(:set_denormalized_values)
      igc.save!
      igc
    end

    # Activity with nil toc location, but not 'Unlisted' component (see before block)
    let!(:activity_nil_toc) { create_true_false_enhanced_activity(program) }

    # Assessment from the selected program
    let(:assessment_concept) do
      create(
        :concept_for_test,
        program_id: program.id,
        lesson: activity_1.lesson
      )
    end
    let!(:assessment) do
      create(
        :activity,
        concept: assessment_concept,
        activity_type: 'exam',
        lesson: activity_1.lesson,
        title: 'Assesment title'
      )
    end

    # Activities not in the selected program
    let!(:activity_3) { create_true_false_enhanced_activity(program_2) }
    let!(:activity_4) { create_cumulative_matching_activity(program_2) }

    before do
      activity_unlisted.component_name = 'Unlisted'
      activity_unlisted.toc_location = nil
      activity_unlisted.save!
      activity_nil_toc.toc_location = nil
      activity_nil_toc.save!
    end

    describe '#each' do
      it 'returns rows of activity data' do

        activities = [activity_1, activity_2, activity_unlisted]
        expected = activities.map.with_index do |act, index|
          activity = activities[index]
          [
            program.id,
            program.title,
            activity.lesson.unit.name,
            activity.lesson.name,
            activity.concept_name,
            activity.component_name,
            activity.title,
            activity.cms_activity_id,
            activity.activity_type,
            "https://#{VtextDataGenerator::MAESTRO_URL}/sections/0/activities/#{activity.id}",
            "",
            "",
            ""
          ]
        end

        set = described_class.new(program.id)

        # map tests each under the hood
        expect(set.map { |row| row }).to eq(expected)
      end
    end
  end
end
