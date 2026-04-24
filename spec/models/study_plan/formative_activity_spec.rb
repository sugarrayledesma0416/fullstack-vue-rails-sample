describe StudyPlan::FormativeActivity do
  let(:content_object) do
    MaestroActivityEngine::ActivityContent::DiagnosticV2::FormativeActivity.new(
      999, 'Activity Title'
    )
  end

  let(:params){ { lesson: lesson } }
  let(:formative_activity) { described_class.new(content_object, params) }
  let(:lesson) { create(:lesson) }
  let!(:activity) { create(:activity, cms_activity_id: 999, lesson: lesson) }
  let(:matching_summative_concept) { create(:study_plan_concept, reference_id: '1.1') }
  let(:cms_revision_id) { 2 }
  let(:study_plan_concepts) do
    [
      create(
        :study_plan_concept,
        reference_id: '1.1',
        activity: activity,
        created_at: Time.zone.yesterday
      ),
      create(
        :study_plan_concept,
        reference_id: '1.2',
        activity: activity,
        created_at: Time.zone.yesterday
      ),
      create(
        :study_plan_concept,
        reference_id: '1.1',
        activity: activity,
        cms_revision_id: cms_revision_id,
        created_at: Time.zone.today
      )
    ]
  end

  before do
    activity.study_plan_concepts = study_plan_concepts
    activity.save
  end

  describe '#concept_reference_ids' do
    it 'returns the concept references in an Array' do
      expect(formative_activity.concept_reference_ids).to eq(['1.1', '1.2'])
    end
  end

  describe '#concept_score' do
    let(:params) do
      {
        lesson: lesson,
        user_id: user.id,
        section_id: section.id
      }
    end

    let(:recommendation) do
      create(:recommendation, cms_activity_id: 999, study_plan_concept: study_plan_concepts.first)
    end

    let(:new_recommendation) do
      create(
        :recommendation,
        cms_activity_id: 999,
        study_plan_concept: study_plan_concepts[2],
        title: 'New Recommendation'
      )
    end

    let(:user) { create(:user) }
    let(:section) { create(:section) }

    context 'when the student has an attempt' do
      before do
        create(
          :attempt,
          user_id: user.id,
          section_id: section.id,
          activity_id: activity.id,
          cms_revision_id: cms_revision_id
        )
        create(:user_reading, user_id: user.id, recommendation: recommendation, concept_score: 100)
        create(:user_reading, user_id: user.id, recommendation: new_recommendation, concept_score: 75)
      end

      it "returns the score for the most recent attempt for the given concept's reference id" do
        expect(formative_activity.concept_score(matching_summative_concept)).to eq(75)
      end

      it 'does not return nil when there is a phantom activity' do
        create(:activity,
               cms_activity_id: activity.cms_activity_id,
               lesson: lesson,
               cms_revision_id: cms_revision_id,
               title: 'Other M3 Activity Title')
        expect(formative_activity.concept_score(matching_summative_concept)).to eq(75)
      end
    end

    context 'when the user has not made an attempt' do
      it 'returns nil' do
        expect(formative_activity.concept_score(matching_summative_concept)).to be_nil
      end
    end
  end

  describe '#score' do
    context 'when there is a submission' do
      let(:grade_object) { OpenStruct.new formatted_submitted_not_due_score: 100 }

      it 'returns the score' do
        allow(GradebookEngine::GradebookAPI).to receive(:find_student_grade).and_return(grade_object)
        expect(formative_activity.score).to eq(100)
      end
    end

    context 'when there is no submission' do
      it 'returns zero' do
        allow(GradebookEngine::GradebookAPI).to receive(:find_student_grade).and_return(nil)
        expect(formative_activity.score).to eq(0)
      end
    end
  end

  describe '#score_formatted_for_student_study_plan' do
    context 'when there is a submission' do
      let(:grade_object) { OpenStruct.new formatted_submitted_not_due_score: 100 }

      it 'returns the score' do
        allow(GradebookEngine::GradebookAPI).to receive(:find_student_grade).and_return(grade_object)
        expect(formative_activity.score_formatted_for_student_study_plan).to eq(100)
      end
    end

    context 'when there is no submission' do
      it 'returns N/A' do
        allow(GradebookEngine::GradebookAPI).to receive(:find_student_grade).and_return(nil)
        expect(formative_activity.score_formatted_for_student_study_plan).to eq('N/A')
      end
    end
  end

  describe '#title' do
    context 'when a title is specified in the content_object' do
      let(:content_object) do
        MaestroActivityEngine::ActivityContent::DiagnosticV2::FormativeActivity.new(
          999, 'Activity Title'
        )
      end

      let!(:activity) do
        create(:activity, cms_activity_id: 999, lesson: lesson, title: "M3 Activity Title")
      end

      it 'returns the given title' do
        expect(formative_activity.title).to eq('Activity Title')
      end
    end

    context 'when a title is not specified in the content_object' do
      let(:content_object) do
        MaestroActivityEngine::ActivityContent::DiagnosticV2::FormativeActivity.new(
          999, nil
        )
      end

      let!(:activity) do
        create(:activity, cms_activity_id: 999, lesson: lesson, title: 'M3 Activity Title')
      end

      it 'returns the m3 activity title' do
        expect(formative_activity.title).to eq('M3 Activity Title')
      end

      it 'returns the activity title of the version of the activity submitted by the student' do
        # This can happen if there are phantom activities.
        other_activity = create(:activity, cms_activity_id: activity.cms_activity_id, lesson: lesson, title: 'Other M3 Activity Title')
        user = create(:student)
        section = create(:section)
        params = { lesson:, user_id: user.id, section_id: section.id }
        create(
          :attempt,
          user_id: user.id,
          section_id: section.id,
          activity_id: other_activity.id,
          cms_revision_id: cms_revision_id
        )
        formative_activity = described_class.new(content_object, params)

        expect(formative_activity.title).to eq('Other M3 Activity Title')
      end
    end
  end

  describe '#activity_lesson' do
    it 'returns the lesson of the underlying activity' do
      expect(formative_activity.activity_lesson).to eq activity.lesson
    end
  end
end
