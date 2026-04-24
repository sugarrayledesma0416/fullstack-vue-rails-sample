describe StudyPlanConceptsPresenter do
  describe '#readings' do
    let(:program_id) { create(:program).id }
    let(:user_id) { create(:user).id }
    let(:activity) { create(:activity, lesson: create(:lesson)) }
    let(:study_plan_concept_1) do
      create(:study_plan_concept, activity: activity, program_id: program_id)
    end
    let(:study_plan_concept_2) do
      create(:study_plan_concept, activity: activity, program_id: program_id)
    end
    let(:presenter) { described_class.new(program_id, user_id) }

    let(:concept_recommendation_1_1) do
      create(:recommendation, study_plan_concept: study_plan_concept_1)
    end

    let(:concept_recommendation_1_2) do
      create(:recommendation, study_plan_concept: study_plan_concept_1)
    end

    let(:concept_recommendation_2_1) do
      create(:recommendation, study_plan_concept: study_plan_concept_2)
    end

    let(:concept_recommendation_2_2) do
      create(:recommendation, study_plan_concept: study_plan_concept_2)
    end

    before do
      create(:user_reading, user_id: user_id, recommendation: concept_recommendation_1_1)
      create(:user_reading, user_id: user_id, recommendation: concept_recommendation_1_2)
      create(:user_reading, user_id: user_id, recommendation: concept_recommendation_2_1)
      create(:user_reading, user_id: user_id, recommendation: concept_recommendation_2_2)
    end

    it 'returns only the activities and lesson names for the study plan concepts found' do
      expect(presenter.readings.size).to eq 1
    end

    it 'returns readings with activity and lesson name' do
      reading = presenter.readings.first
      expect(reading.activity).to eq activity
      expect(reading.text).to eq "#{activity.lesson.display_name} - Study plan"
    end
  end
end
