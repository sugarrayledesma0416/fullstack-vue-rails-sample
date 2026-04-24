describe StudyPlanConceptsCreator do
  let(:study_plan_practice_test_content_xml) do
    File.read(
      File.join('db', 'example_data', 'xml', 'study_plan_practice_test_activity.xml')
    )
  end

  let(:object_to_publish) { create(:activity) }

  before do
    object_to_publish.extend(ActivityXmlContentHelper)
    object_to_publish.content = study_plan_practice_test_content_xml
    object_to_publish.send(:assign_new_content_instance) # Force content parsing
    object_to_publish.save!
  end

  describe '.batch_create' do
    let(:activity) { object_to_publish }
    let(:program) { create(:program) }
    let(:other_program_id) { create(:program).id }

    before do
      allow(activity).to receive(:program).and_return(program)
    end

    context 'when activity is in process of being updated' do
      it 'creates concepts for given activity and the activity program' do
        described_class.batch_create([activity], other_program_id)

        expect(
          StudyPlanConcept.where(
            activity_id: activity.id,
            program_id: activity.program.id
          )
        ).to exist

        expect(
          StudyPlanConcept.where(
            activity_id: activity.id,
            program_id: other_program_id
          )
        ).not_to exist
      end
    end

    context 'when activity has been updated' do
      context 'when activity has no program' do
        it 'creates concepts for the given activity and the specified program id' do
          allow(activity).to receive(:persisted?).and_return(true)
          allow(activity).to receive(:program).and_return(nil)

          described_class.batch_create([activity], other_program_id)

          concept_existence = StudyPlanConcept.where(
            activity_id: activity.id,
            program_id: activity.program&.id
          ).exists?

          another_concept_existence = StudyPlanConcept.where(
            activity_id: activity.id,
            program_id: other_program_id
          ).exists?
          expect(concept_existence).to eq false
          expect(another_concept_existence).to eq true
        end
      end
    end

    context 'when activity has been updated' do
      context 'when activity has program' do
        it 'creates concepts for given activity and activity program' do
          allow(activity).to receive(:persisted?).and_return(true)
          allow(activity).to receive(:program).and_return(program)

          expect do
            described_class.batch_create([activity], program.id)
          end.to change(StudyPlanConcept, :count)
        end
      end
    end
  end

  describe '#create' do
    let(:study_plan_practice_test_content_xml) do
      File.read(File.join('db', 'example_data', 'xml', 'study_plan_practice_test_activity.xml'))
    end
    let(:program_id) { create(:program).id }
    let(:object_to_publish)         { create(:activity) }
    let(:published_object_concepts) { object_to_publish.content_object.concepts }
    let(:published_object_concept)  { published_object_concepts.first }
    let(:creator)                   { described_class.new(object_to_publish, program_id) }
    let(:study_plan_concepts)       { StudyPlanConcept.where(activity_id: object_to_publish.id) }
    let(:study_plan_concept)        { study_plan_concepts.first }

    context 'when the activity has study plan concepts already' do
      before do
        creator.create
      end

      it 'does not create new ones' do
        expect { creator.create }.not_to change(StudyPlanConcept, :count)
      end
    end

    it 'creates valid study plan concepts' do
      creator.create # Try to create study plan concepts

      expect(study_plan_concept.program_id).to eq program_id
      expect(study_plan_concept.cms_revision_id).to eq object_to_publish.cms_revision_id
      expect(study_plan_concept.reference_id).to eq published_object_concept.ref
      expect(study_plan_concept.title).to eq published_object_concept.title
      expect(study_plan_concept.threshold).to eq published_object_concept.threshold
      expect(study_plan_concept.recommendations).not_to be_empty
    end

    it "creates a study plan concept for each activity's concept" do
      concept_refs = published_object_concepts.map(&:ref)

      creator.create

      expect(study_plan_concepts).not_to be_empty

      study_plan_concepts.each do |study_plan_concept|
        expect(concept_refs).to include(study_plan_concept.reference_id)
      end
    end

    it "creates recommendations by study plan concept for each activity's concept reference" do
      creator.create

      reference_count = (published_object_concept.external_references +
        published_object_concept.supplemental_activities).size

      # Because the XML contains vocab link label, it adds a new recommendation, so we need to
      # increase by one the reference count
      expect(study_plan_concept.recommendations.size).to eq reference_count + 1
    end

    context 'when concept has vocabulary_link_label' do
      it "creates a recommendation of type 'vocabulary', first" do
        creator.create

        vocabulary_recommendation = study_plan_concept.recommendations.first

        expect(vocabulary_recommendation.recommendation_type).to eq 'vocabulary'
        expect(vocabulary_recommendation.title).to eq published_object_concept.vocabulary_link_label
      end
    end

    context 'when it does not exists a concept with vocabulary_link_label' do
      before do
        object_to_publish.content_object.concepts.to_a.delete_if do |concept|
          concept.vocabulary_link_label.present?
        end
      end

      it "does not create a recommendation of type 'vocabulary'" do
        creator.create

        recommendations = study_plan_concept.recommendations
        expect(recommendations.where(recommendation_type: 'vocabulary')).to be_empty
      end
    end
  end
end
