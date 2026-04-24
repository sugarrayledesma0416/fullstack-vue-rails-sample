describe UserReadingsGenerator do
  describe '#generate' do
    let(:user_id) { user.id }
    let(:program) { create(:program) }
    let(:section) { instance_double(Section) }
    let(:user) { create(:user) }
    let(:activity) { create(:activity) }
    let(:study_plan_concept_1) do
      create(
        :study_plan_concept,
        activity: activity,
        program: program,
        cms_revision_id: activity.cms_revision_id
      )
    end
    let(:study_plan_concept_2) do
      create(
        :study_plan_concept,
        activity: activity,
        program: program,
        cms_revision_id: activity.cms_revision_id
      )
    end
    let(:results) { instance_double(MaestroActivityEngine::ActivityContent::Results) }
    let(:generator) { described_class.new(activity, results, section, user) }

    before do
      allow(activity).to receive(:activity_type).and_return('study_plan_practice_test')
      allow(activity).to receive(:program) { program }
      allow(activity.notifications).to receive(:dispatch)
      allow(results).to receive(:concept_percent).with(
        study_plan_concept_1.reference_id
      ).and_return(40)
      allow(results).to receive(:concept_percent).with(
        study_plan_concept_2.reference_id
      ).and_return(90)
      create(:recommendation, study_plan_concept: study_plan_concept_1)
      create(:supplemental_recommendation, study_plan_concept: study_plan_concept_1)
      create(:recommendation, study_plan_concept: study_plan_concept_2)
      create(:supplemental_recommendation, study_plan_concept: study_plan_concept_2)
    end

    it 'generates a user reading for each recommendation for the activity' do
      generator.generate
      user_readings = UserReading.all
      recommendations = StudyPlanConceptRecommendation.all

      expect(user_readings.size).to eq recommendations.size
    end

    it 'creates a StudyPlanCreatedNotification' do
      generator.generate
      expect(activity.notifications).to have_received(:dispatch).with(
        'StudyPlanCreated',
        section: section, user: user
      )
    end

    context 'when generating valid user readings' do
      let(:user_readings) { UserReading.all }
      let(:recommendation) do
        StudyPlanConceptRecommendation.where(
          study_plan_concept_id: study_plan_concept_1
        ).first
      end

      let(:user_reading) do
        user_readings.detect { |reading| reading.recommendation == recommendation }
      end

      it 'sets the score from the study plan concept' do
        generator.generate
        expect(user_reading.concept_score).to eq results.concept_percent(
          study_plan_concept_1.reference_id
        )
      end

      context 'with a study_plan_practice_test activity type' do
        context 'when score for the concept does not reach the concept threshold' do
          it "sets reading as 'not viewed'" do
            generator.generate
            expect(user_reading).not_to be_viewed
          end
        end

        context 'when score for the concept reaches the concept threshold' do
          it "sets reading as 'viewed'" do
            generator.generate
            recommendation = StudyPlanConceptRecommendation.where(
              study_plan_concept_id: study_plan_concept_2
            ).first
            user_reading = user_readings.detect do |reading|
              reading.recommendation == recommendation
            end
            expect(user_reading).to be_viewed
          end
        end
      end

      context 'with a diagnostic_v2 activity type' do
        context 'when score for the concept does not reach the concept threshold' do
          it "sets reading as 'not viewed'" do
            allow(activity).to receive(:activity_type).and_return('diagnostic_v2')
            generator.generate
            expect(user_reading).not_to be_viewed
          end
        end

        context 'when score for the concept reaches the concept threshold' do
          # for diagnostic_v2, we always want the intial viewed status as false.
          # It only becomes true after the user clicks on the reading recommendation
          # in the study plan.
          it "sets reading as 'not viewed'" do
            allow(activity).to receive(:activity_type).and_return('diagnostic_v2')
            generator.generate
            recommendation = StudyPlanConceptRecommendation.where(
              study_plan_concept_id: study_plan_concept_2
            ).first
            user_reading = user_readings.detect do |reading|
              reading.recommendation == recommendation
            end
            expect(user_reading).not_to be_viewed
          end
        end
      end
    end

    context 'when activity is not a study plan practice test' do
      it 'does not generate readings' do
        allow(UserReading).to receive(:create!)
        allow(activity).to receive(:activity_type).and_return('exam')
        generator.generate
        expect(UserReading).not_to have_received(:create!)
      end
    end

    context 'when user already has readings for the activity' do
      it 'does not generate readings' do
        allow(UserReading).to receive(:create!)
        create(
          :user_reading,
          user_id: user_id,
          recommendation: StudyPlanConceptRecommendation.first
        )
        generator.generate
        expect(UserReading).not_to have_received(:create!)
      end
    end
  end

  describe UserReadingsGenerator::DecoratedConcept do
    describe '#attributes' do
      let(:study_plan_concept) { build_stubbed(:study_plan_concept) }
      let(:concept_score) { 50 }
      let(:decorated_concept) { described_class.new(study_plan_concept, concept_score) }

      it 'returns a hash with score and viewed keys' do
        %i[concept_score viewed].each do |key|
          expect(decorated_concept.attributes.keys).to include(key)
        end
      end

      it 'sets the passed concept score in the attribute hash' do
        expect(decorated_concept.attributes[:concept_score]).to eq concept_score
      end

      context 'when the threshold flag is true' do
        context "when the passed score is less or equal to the concept's threshold" do
          it 'sets viewed to false' do
            expect(decorated_concept.attributes[:viewed]).to be_falsey
          end
        end

        context "when the passed score is greater than the concept's threshold" do
          it 'sets viewed to true' do
            decorated_concept = described_class.new(study_plan_concept, 90)
            expect(decorated_concept.attributes[:viewed]).to be_truthy
          end
        end
      end

      context 'when the threshold flag is false' do
        it 'sets viewed to false' do
          decorated_concept = described_class.new(study_plan_concept, 90, false)
          expect(decorated_concept.attributes[:viewed]).to be_falsey
        end
      end
    end
  end
end
