describe StudyPlan::ConceptWithScores do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, program: program) }
  let(:program) { create(:program) }
  let(:section) { create(:section) }
  let(:concept_params) do
    {
      user_id: user.id,
      section_id: section.id,
      program_id: program.id,
      unit_id: unit.id
    }
  end

  let(:concept) { create(:study_plan_concept) }
  let(:reference_recommendation) do
    create(:recommendation, study_plan_concept: concept)
  end

  let(:supplemental_recommendation) do
    create(
      :supplemental_recommendation,
      study_plan_concept: concept
    )
  end

  let(:concept_with_scores) { described_class.new(concept, concept_params, [], [].size) }
  let(:user_reading) do
    UserReading.where(
      study_plan_concept_recommendation_id: reference_recommendation.id
    ).first
  end

  before do
    create(
      :user_reading,
      user_id: user.id,
      recommendation: reference_recommendation
    )
    create(
      :user_reading,
      user_id: user.id,
      recommendation: supplemental_recommendation
    )
  end

  describe '#readings' do
    let(:readings) { concept_with_scores.readings }

    it 'uses sorted recommendations from concept' do
      allow(concept).to receive(:sorted_recommendations).and_return([])
      readings
      expect(concept).to have_received(:sorted_recommendations)
    end

    it 'returns 2 readings' do
      expect(readings.size).to eq 2
    end

    it 'returns Readings instances for each UserReading' do
      expect(readings.first).to be_a StudyPlan::Reading
    end
  end

  describe '#score' do
    it 'returns the concept score for the first associated user reading' do
      expect(concept_with_scores.score).to eq user_reading.concept_score
    end
  end

  describe '#needs_reading?' do
    context 'when the reading score value is less than or equal to the concept threshold' do
      it 'returns true' do
        # rubocop:disable Rails/SkipsModelValidations
        UserReading.update_all(concept_score: 50)
        # rubocop:enable Rails/SkipsModelValidations
        expect(concept_with_scores).to be_needs_reading
      end
    end

    context 'when the reading score value is greater than the concept threshold' do
      it 'returns false' do
        expect(concept_with_scores).not_to be_needs_reading
      end
    end
  end

  describe '#complete?' do
    context 'when all readings have been viewed' do
      it 'returns true' do
        # rubocop:disable Rails/SkipsModelValidations
        UserReading.update_all(viewed: true)
        # rubocop:enable Rails/SkipsModelValidations
        expect(concept_with_scores).to be_complete
      end
    end

    context 'when the reading score value is greater than the concept threshold' do
      it 'returns false' do
        expect(concept_with_scores).not_to be_complete
      end
    end
  end

  describe '#formative_activity_scores' do
    context 'when the reference_id is missing from one or more activities concept reference ids' do
      let(:concept_with_scores) do
        described_class.new(concept,
                            concept_params,
                            [formative_activity, formative_activity],
                            [formative_activity, formative_activity].size)
      end
      let(:formative_activity) { StudyPlan::FormativeActivity.new({}, {}) }

      it 'returns "N/A" for each' do
        allow(formative_activity).to receive(:concept_reference_ids).and_return([])

        na_values = concept_with_scores.formative_activity_scores.select { |s| s == 'N/A' }
        expect(na_values.count).to eq(2)
      end
    end

    context 'when there are no formative activities for a concept' do
      let(:formative_activity) { StudyPlan::FormativeActivity.new({}, {}) }
      let(:formative_activities_amount) { [formative_activity, formative_activity].size }
      let(:concept_with_scores) do
        described_class.new(concept,
                            concept_params,
                            [],
                            formative_activities_amount)
      end

      it 'returns an array with N/A and size equal to the expected formative activities hash' do
        expect(concept_with_scores.formative_activity_scores).to eq(
          ['N/A'] * formative_activities_amount
        )
      end
    end

    context 'when there is one formative activity for a concept and \
             the total size of formative activities is higher' do
      let(:formative_activity) { StudyPlan::FormativeActivity.new({}, {}) }
      let(:formative_activities_amount) { [formative_activity, formative_activity].size }
      let(:concept_with_scores) do
        described_class.new(concept,
                            concept_params,
                            [formative_activity],
                            formative_activities_amount)
      end

      before do
        allow(formative_activity).to receive(:concept_reference_ids).and_return(
          [StudyPlanConcept.first.reference_id]
        )
        allow(formative_activity).to receive(:concept_score).and_return(60)
      end

      it 'returns an array with the score of the activities that have one, \
          and N/A from those activities that do not have a score' do
        formative_activity_scores_by_default = ['N/A'] * formative_activities_amount
        formative_activity_scores_by_default[0] = formative_activity.concept_score

        expect(concept_with_scores.formative_activity_scores).to eq(
          formative_activity_scores_by_default
        )
      end
    end

    context 'When there is a formative activity for each concept with its score' do
      let(:formative_activity_1) { StudyPlan::FormativeActivity.new({}, {}) }
      let(:formative_activity_2) { StudyPlan::FormativeActivity.new({}, {}) }
      let(:formative_activities_amount) { [formative_activity_1, formative_activity_2].size }
      let(:concept_with_scores) do
        described_class.new(concept,
                            concept_params,
                            [formative_activity_1, formative_activity_2],
                            formative_activities_amount)
      end

      before do
        allow(formative_activity_1).to receive(:concept_reference_ids).and_return(
          [StudyPlanConcept.first.reference_id]
        )
        allow(formative_activity_1).to receive(:concept_score).and_return(30)
        allow(formative_activity_2).to receive(:concept_reference_ids).and_return(
          [StudyPlanConcept.first.reference_id]
        )
        allow(formative_activity_2).to receive(:concept_score).and_return(60)
      end

      it 'returns an array with the score of the activities that have one, \
          and N/A from those activities that do not have a score' do
        formative_activity_scores_by_default = ['N/A'] * formative_activities_amount
        formative_activity_scores_by_default[0] = formative_activity_1.concept_score
        formative_activity_scores_by_default[1] = formative_activity_2.concept_score

        expect(concept_with_scores.formative_activity_scores).to eq(
          formative_activity_scores_by_default
        )
      end
    end

    it 'returns an Array' do
      expect(concept_with_scores.formative_activity_scores).to be_an(Array)
    end

    it 'returns each score as a string' do
      expect(concept_with_scores.formative_activity_scores).to all be_a(String)
    end
  end

  describe '#score_difference' do
    let(:concept_with_scores) do
      described_class.new(concept,
                          concept_params,
                          [formative_activity],
                          [formative_activity].size)
    end
    let(:formative_activity) { StudyPlan::FormativeActivity.new({}, {}) }

    it "returns the difference of the concept's formative activity score and the activity's" do
      allow(formative_activity).to receive(:concept_reference_ids).and_return(
        [StudyPlanConcept.first.reference_id]
      )
      allow(formative_activity).to receive(:concept_score).and_return(60)

      expect(concept_with_scores.score_difference).to eq(20)
    end

    it "returns 'N/A' if there is no formative activity score" do
      allow(formative_activity).to receive(:concept_reference_ids).and_return(
        ['foo']
      )

      expect(concept_with_scores.score_difference).to eq('N/A')
    end
  end
end
