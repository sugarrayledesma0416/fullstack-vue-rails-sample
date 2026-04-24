require 'rails_helper'
require 'light-service/testing'

RSpec.describe FindLessonDiagnosticV2Activities do
  include RspecJsContentHelpers

  let(:course) { create(:course, program:) }
  let(:lesson) { create(:lesson) }
  let(:order) { 'asc' }
  let(:program) { lesson.unit.program }
  let(:section) { create(:section, course:) }
  let(:summative_activity) { create_summative_activity(program, lesson:) }
  let(:study_plan_concept) do
    create(:study_plan_concept, program:, activity: summative_activity, cms_revision_id: 10)
  end
  let(:student_1) { create(:student, first_name: 'Alan', last_name: 'Alvarez') }
  let(:student_2) { create(:student, first_name: 'Mario', last_name: 'Martinez') }
  let(:student_3) { create(:student, first_name: 'Zelda', last_name: 'Zapata') }
  let(:context) do
    LightService::Testing::ContextFactory
      .make_from(SectionPracticeTestAnalyzer)
      .for(described_class)
      .with(context_params)
  end
  let(:context_params) do
    {
      order:,
      section:,
      concept_id: study_plan_concept.id,
      lesson: [lesson]
    }
  end

  before do
    section.students << student_1
    section.students << student_2
    section.students << student_3
  end

  context 'when there are not summative and formative activities in the lessons' do
    it 'fails the context' do
      results = described_class.execute(context)
      expect(results).to be_failure
    end

    it 'generates a failure message' do
      results = described_class.execute(context)
      expect(results.message).to eq 'This lesson does not have Practice Test activities.'
    end
  end

  context 'when there are summative and formative activities in the lessons' do
    let(:assignment) do
      create(:assignment, assignable: summative_activity, section:)
    end
    let(:formative_activity) { create_formative_activity(program, lesson:) }
    let(:formative_study_plan_concept) do
      create(:study_plan_concept, program:, activity: formative_activity, cms_revision_id: 20, reference_id: study_plan_concept.reference_id)
    end
    let(:summative_study_plan_concept_recommendation) do
      study_plan_concept.recommendations.create!(
        cms_activity_id: summative_activity.cms_activity_id,
        recommendation_type: 'supplemental',
        title: 'Practice'
      )
    end
    let(:formative_study_plan_concept_recommendation) do
      formative_study_plan_concept.recommendations.create!(
        cms_activity_id: formative_activity.cms_activity_id,
        recommendation_type: 'supplemental',
        title: 'Practice'
      )
    end
    let(:student_scores) do
      summative_study_plan_concept_recommendation.user_readings.create!(
        user: student_1, concept_score: 3
      )
      summative_study_plan_concept_recommendation.user_readings.create!(
        user: student_2, concept_score: 1
      )
      summative_study_plan_concept_recommendation.user_readings.create!(
        user: student_3, concept_score: 2
      )
      formative_study_plan_concept_recommendation.user_readings.create!(
        user: student_1, concept_score: 7
      )
      formative_study_plan_concept_recommendation.user_readings.create!(
        user: student_2, concept_score: 9
      )
      formative_study_plan_concept_recommendation.user_readings.create!(
        user: student_3, concept_score: 4
      )
      [
        OpenStruct.new(
          user_id: student_1.id,
          formatted_submitted_not_due_score: 20,
          submitted?: true
        ),
        OpenStruct.new(
          user_id: student_2.id,
          formatted_submitted_not_due_score: 50,
          submitted?: true
        ),
        OpenStruct.new(
          user_id: student_3.id,
          formatted_submitted_not_due_score: 30,
          submitted?: true
        )
      ]
    end

    before do
      allow(GradebookEngine::GradebookAPI).to receive(:find_section_assignment_grades).and_return(student_scores)
      section.students.each do |student|
        create(:attempt, user: student, section:, activity: summative_activity, status_code: AttemptStatus::CODE_COMPLETED, cms_revision_id: study_plan_concept.cms_revision_id)
        create(:attempt, user: student, section:, activity: formative_activity, status_code: AttemptStatus::CODE_COMPLETED, cms_revision_id: formative_study_plan_concept.cms_revision_id)
      end
      assignment
    end

    it 'assigns activities to the context' do
      results = described_class.execute(context)
      expect(results.activities).to match [summative_activity, formative_activity]
    end

    it 'assigns concepts to the context' do
      results = described_class.execute(context)
      expect(results.concepts).to eq []
    end

    it 'assigns assignments to the context' do
      results = described_class.execute(context)
      expect(results.assignments).to eq(
        {
          formative: [],
          summative: assignment
        }
      )
    end
  end
end
