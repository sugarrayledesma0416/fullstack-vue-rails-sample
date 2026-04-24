describe Gradebook::SectionPracticeTestPresenter do
  let(:program) { create(:program) }
  let(:lesson) { create(:lesson) }
  let(:unit_with_lesson) { create(:unit, lessons: [lesson], program: program) }
  let(:section) { create(:section) }
  let(:presenter) do
    described_class.new(
      program_id: program.id,
      section_id: section.id,
      lesson_id: lesson.id
    )
  end

  describe '#missing_activities?' do
    it 'returns true if the error code indicates missing activities' do
      allow(presenter).to(receive(:results)).and_return(OpenStruct.new(error_code: 1))
      expect(presenter.missing_activities?).to eq(true)
    end

    it 'returns false if the error code is not set' do
      allow(presenter).to(receive(:results)).and_return(OpenStruct.new(error_code: nil))
      expect(presenter.missing_activities?).to eq(false)
    end

    it 'returns false if the error code is not for missing activities' do
      allow(presenter).to(receive(:results)).and_return(OpenStruct.new(error_code: 'foo'))
      expect(presenter.missing_activities?).to eq(false)
    end
  end

  describe '#summative_concepts' do
    let(:reference_id_1) { '17.1' }
    let(:reference_id_2) { '17.2' }
    let(:activity) { create(:activity) }
    let(:latest_cms_revision_id) { 100 }
    let(:section_student_aggregator) do
      instance_double(
        SectionAnalytics::PracticeTest::SectionStudentsAggregator,
        summative_concepts: StudyPlanConcept.where(
          activity_id: activity.id
        )
      )
    end

    before do
      allow(presenter).to receive(:section_student_scores).and_return(section_student_aggregator)
      allow(presenter).to receive(:summative_concepts_count).and_return(2)
      # This won't happen in real life, but since there was a bug that caused the order
      # of the study_plan_concept records to be returned randomly and was associated to
      # ordering by created_at, this is the best I can do to have a consistent error case,
      # and test that the latest versions of study_plan_concepts are returned.
      Timecop.travel(10.seconds.from_now) do
        create(:study_plan_concept,
               reference_id: reference_id_1,
               activity_id: activity.id,
               cms_revision_id: latest_cms_revision_id - 1)
        create(:study_plan_concept,
               reference_id: reference_id_2,
               activity_id: activity.id,
               cms_revision_id: latest_cms_revision_id - 2)
      end
      create(:study_plan_concept,
             reference_id: reference_id_2,
             activity_id: activity.id,
             cms_revision_id: latest_cms_revision_id + 2)
      create(:study_plan_concept,
             reference_id: reference_id_1,
             activity_id: activity.id,
             cms_revision_id: latest_cms_revision_id + 1)
    end

    it 'returns the latest version of study_plan_concept in the expected order' do
      results = presenter.summative_concepts
      expect(results[0].reference_id).to eq reference_id_1
      expect(results[0].cms_revision_id).to eq(latest_cms_revision_id + 1)
      expect(results[1].reference_id).to eq reference_id_2
      expect(results[1].cms_revision_id).to eq(latest_cms_revision_id + 2)
    end
  end
end
