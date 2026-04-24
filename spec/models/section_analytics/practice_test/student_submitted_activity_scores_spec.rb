describe SectionAnalytics::PracticeTest::StudentSubmittedActivityScores do
  let(:section) { create(:section_with_enrollments) }
  let(:student) { section.current_students_base.first }
  let(:summative_activity) { create(:activity, activity_type: 'diagnostic_v2') }
  let(:summative_assignment) do
    create(:assignment, assignable: summative_activity, section: section, due_date: Date.tomorrow)
  end
  let(:summative_concept) do
    create(
      :study_plan_concept,
      activity: summative_activity,
      reference_id: 'grammar 1.1',
      cms_revision_id: summative_activity.cms_revision_id
    )
  end
  let(:summative_recommendation) do
    create(:recommendation, study_plan_concept: summative_concept)
  end
  let(:formative_activity) { create(:activity, activity_type: 'diagnostic_v2') }
  let(:formative_assignment) do
    create(:assignment, assignable: formative_activity, section: section, due_date: Date.tomorrow)
  end
  let(:formative_concept) do
    create(
      :study_plan_concept,
      activity: formative_activity,
      reference_id: 'grammar 1.1',
      cms_revision_id: formative_activity.cms_revision_id
    )
  end
  let(:formative_recommendation) do
    create(:recommendation, study_plan_concept: formative_concept)
  end
  let(:assignments) { { summative: summative_assignment, formative: formative_assignment } }
  let(:student_concepts) do
    described_class.new(student, summative_activity, [formative_activity], assignments)
  end

  before do
    allow(summative_activity).to receive(:formative_activities).and_return([formative_activity])
  end

  describe '#summative_concept_score_for' do
    context 'when given a formative activity study plan concept' do
      before do
        create(:user_reading, user: student, recommendation: summative_recommendation, concept_score: 90)
        create(
          :attempt,
          activity: summative_activity,
          user: student,
          section: section,
          cms_revision_id: summative_activity.cms_revision_id,
          status_code: AttemptStatus::CODE_COMPLETED
        )
      end

      it 'finds the score associated to the summative concept of the same reference id' do
        expect(student_concepts.summative_concept_score_for(formative_concept)).to eq(90)
      end
    end

    context "when given a current summative activity's concept" do
      context 'when the revision id is different than the one the student has readings for' do
        let(:old_summative_concept) do
          create(
            :study_plan_concept,
            activity: summative_activity,
            reference_id: 'grammar 1.1'
          )
        end

        let(:old_summative_recommendation) do
          create(:recommendation, study_plan_concept: old_summative_concept)
        end

        before do
          create(:user_reading, user: student, recommendation: old_summative_recommendation, concept_score: 90)
          create(
            :attempt,
            activity: summative_activity,
            user: student,
            section: section,
            cms_revision_id: old_summative_concept.cms_revision_id,
            status_code: AttemptStatus::CODE_COMPLETED
          )
        end

        it "finds the score associated to the previous revision's concept of the same reference_id" do
          expect(student_concepts.summative_concept_score_for(summative_concept)).to eq(90)
        end
      end

      context 'when the student has a score for the current concept' do
        before do
          create(:user_reading, user: student, recommendation: summative_recommendation, concept_score: 90)
          create(
            :attempt,
            activity: summative_activity,
            user: student,
            section: section,
            cms_revision_id: summative_activity.cms_revision_id,
            status_code: AttemptStatus::CODE_COMPLETED
          )
        end

        it 'finds the score for that concept' do
          expect(student_concepts.summative_concept_score_for(summative_concept)).to eq(90)
        end
      end
    end
  end

  describe '#formative_concept_score_for' do
    context "when given a current summative activity's concept" do
      context 'when the revision id is different than the one the student has readings for' do
        let(:old_formative_concept) do
          create(
            :study_plan_concept,
            activity: formative_activity,
            reference_id: 'grammar 1.1'
          )
        end

        let(:old_formative_recommendation) do
          create(:recommendation, study_plan_concept: old_formative_concept)
        end

        before do
          create(:user_reading, user: student, recommendation: old_formative_recommendation, concept_score: 90)
          create(
            :attempt,
            activity: formative_activity,
            user: student,
            section: section,
            cms_revision_id: old_formative_concept.cms_revision_id,
            status_code: AttemptStatus::CODE_COMPLETED
          )
        end

        it "finds the score associated to the previous revision's concept of the same reference_id" do
          expect(student_concepts.formative_concept_score_for(formative_concept)).to eq(90)
        end
      end

      context 'when the student has a score for the current concept' do
        before do
          create(:user_reading, user: student, recommendation: formative_recommendation, concept_score: 90)
          create(
            :attempt,
            activity: formative_activity,
            user: student,
            section: section,
            cms_revision_id: formative_activity.cms_revision_id,
            status_code: AttemptStatus::CODE_COMPLETED
          )
        end

        it 'finds the score for that concept' do
          expect(student_concepts.formative_concept_score_for(formative_concept)).to eq(90)
        end
      end
    end
  end

  describe '#supplemental_readings_for' do
    let(:summative_recommendation) do
      create(:recommendation, study_plan_concept: summative_concept, recommendation_type: 'supplemental')
    end
    let(:other_summative_recommendation) do
      create(
        :recommendation,
        study_plan_concept: summative_concept,
        recommendation_type: 'reference'
      )
    end
    let!(:supplemental_summative_reading) do
      create(
        :user_reading,
        user: student,
        recommendation: summative_recommendation,
        concept_score: 90
      )
    end

    before do
      create(
        :user_reading,
        user: student,
        recommendation: other_summative_recommendation,
        concept_score: 90
      )

      create(
        :attempt,
        activity: summative_activity,
        user: student,
        section: section,
        cms_revision_id: summative_activity.cms_revision_id,
        status_code: AttemptStatus::CODE_COMPLETED
      )
    end

    it 'only returns supplmental readings' do
      expect(
        student_concepts.supplemental_readings_for(summative_concept)
      ).to eq([supplemental_summative_reading])
    end
  end

  describe '#review_readings_for' do
    let(:reference_summative_recommendation) do
      create(:recommendation, study_plan_concept: summative_concept, recommendation_type: 'reference')
    end
    let(:vocabulary_summative_recommendation) do
      create(:recommendation, study_plan_concept: summative_concept, recommendation_type: 'vocabulary')
    end
    let(:other_summative_recommendation) do
      create(
        :recommendation,
        study_plan_concept: summative_concept,
        recommendation_type: 'supplemental'
      )
    end
    let!(:reference_summative_reading) do
      create(
        :user_reading,
        user: student,
        recommendation: reference_summative_recommendation,
        concept_score: 90
      )
    end
    let!(:vocabulary_summative_reading) do
      create(
        :user_reading,
        user: student,
        recommendation: vocabulary_summative_recommendation,
        concept_score: 90
      )
    end
    let!(:other_concept) do
      create(
        :study_plan_concept,
        activity: summative_activity,
        reference_id: 'foo',
        cms_revision_id: summative_activity.cms_revision_id
      )
    end
    let!(:other_concept_recommendation) do
      create(
        :recommendation,
        study_plan_concept: other_concept,
        recommendation_type: 'vocabulary'
      )
    end
    let!(:other_concept_reading) do
      create(
        :user_reading,
        user: student,
        recommendation: other_concept_recommendation,
        concept_score: 90
      )
    end

    before do
      create(
        :user_reading,
        user: student,
        recommendation: other_summative_recommendation,
        concept_score: 90
      )

      create(
        :attempt,
        activity: summative_activity,
        user: student,
        section: section,
        cms_revision_id: summative_activity.cms_revision_id,
        status_code: AttemptStatus::CODE_COMPLETED
      )
    end

    it 'includes reference readings' do
      expect(
        student_concepts.review_readings_for(summative_concept)
      ).to include(reference_summative_reading)
    end

    it 'includes vocabulary readings' do
      expect(
        student_concepts.review_readings_for(summative_concept)
      ).to include(vocabulary_summative_reading)
    end

    it 'excludes non-reference type readings' do
      other_summative_reading = create(
        :user_reading,
        user: student,
        recommendation: other_concept_recommendation,
        concept_score: 90
      )
      expect(
        student_concepts.review_readings_for(summative_concept)
      ).not_to include(other_summative_reading)
    end

    it 'does not include readings from concepts with different reference_ids' do
      expect(
        student_concepts.review_readings_for(summative_concept)
      ).not_to include(other_concept_reading)
    end
  end
end
