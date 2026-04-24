require 'rails_helper'
require 'light-service/testing'

RSpec.describe FindActivityConceptScoresAndGrades do
  include RspecJsContentHelpers

  let(:summative_activity) { create_summative_activity(program, lesson:) }
  let(:formative_activity) { create_formative_activity(program, lesson:) }
  let(:course) { create(:course, program:) }
  let(:lesson) { create(:lesson) }
  let(:order) { 'asc' }
  let(:program) { lesson.unit.program }
  let(:section) { create(:section, course:) }
  let(:study_plan_concept) do
    create(:study_plan_concept, program:, activity: summative_activity, cms_revision_id: summative_activity.cms_revision_id)
  end
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
  let(:student_1) { create(:student, first_name: 'Alan', last_name: 'Alvarez') }
  let(:student_2) { create(:student, first_name: 'Mario', last_name: 'Martinez') }
  let(:student_3) { create(:student, first_name: 'Zelda', last_name: 'Zapata') }
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
  let(:context) do
    LightService::Testing::ContextFactory
      .make_from(SectionPracticeTestAnalyzer)
      .for(described_class)
      .with(context_params)
  end
  let(:context_params) do
    {
      lesson:,
      section:,
      order:,
      concept_id: study_plan_concept.id
    }
  end

  before do
    allow(GradebookEngine::GradebookAPI).to receive(:find_section_assignment_grades).and_return(student_scores)
    section.students << student_1
    section.students << student_2
    section.students << student_3
    section.students.each do |student|
      create(:attempt, user: student, section:, activity: summative_activity, status_code: AttemptStatus::CODE_COMPLETED, cms_revision_id: study_plan_concept.cms_revision_id)
      create(:attempt, user: student, section:, activity: formative_activity, status_code: AttemptStatus::CODE_COMPLETED, cms_revision_id: formative_study_plan_concept.cms_revision_id)
    end
    create(:assignment, assignable: summative_activity, section:)
  end

  it 'adds the section_student_scores to the context' do
    results = described_class.execute(context)
    expect(
      results.section_student_scores
    ).to be_a(SectionAnalytics::PracticeTest::SectionStudentsAggregator)
    expect(
      results.section_student_scores.student_rows.map(&:student)
    ).to eq([student_1, student_2, student_3])
  end

  it 'adds the section_averages to the context' do
    results = described_class.execute(context)
    expect(
      results.section_averages[0]
    ).to be_a(SectionAnalytics::PracticeTest::SectionConceptAverages)
    expect(
      results.section_averages[0].average
    ).to eq 6
  end

  it 'returns the section_average in the reference order' do
    study_plan_concept.update(reference_id: '1.0')
    (1..4).each do |index|
      create(
        :study_plan_concept,
        program:,
        activity: summative_activity,
        reference_id: "1.#{index}",
        cms_revision_id: summative_activity.cms_revision_id
      )
    end
    results = described_class.execute(context)
    expect(
      results.section_averages.map(&:reference_id)
    ).to eq %w[1.0 1.1 1.2 1.3 1.4]
  end

  it 'adds the summative average to the context' do
    results = described_class.execute(context)
    expect(
      results.summative_average
    ).to eq 33
  end
end
