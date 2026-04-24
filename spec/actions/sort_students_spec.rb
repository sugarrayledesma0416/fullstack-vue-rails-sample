require 'rails_helper'
require 'light-service/testing'

RSpec.describe SortStudents do
  include RspecJsContentHelpers

  let(:summative_activity) { create_summative_activity(program, lesson:) }
  let(:formative_activity) { create_formative_activity(program, lesson:) }
  let(:course) { create(:course, program:) }
  let(:lesson) { create(:lesson) }
  let(:order) { 'asc' }
  let(:program) { lesson.unit.program }
  let(:section) { create(:section, course:) }
  let(:study_plan_concept) do
    create(:study_plan_concept, program:, activity: summative_activity, cms_revision_id: 10)
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

  it 'keeps the default order of the score is no sort param is given' do
    results = described_class.execute(context)
    expect(
      results.section_student_scores.student_rows.map(&:student)
    ).to eq [student_1, student_2, student_3]
  end

  it 'sorts the students scores data by name' do
    context_params[:sort_by] = 'name'
    context_params[:order] = 'desc'
    results = described_class.execute(context)
    expect(
      results.section_student_scores.student_rows.map(&:student)
    ).to eq [student_3, student_2, student_1]
  end

  it 'sorts the students scores data by summative_grade' do
    context_params[:sort_by] = 'summative_grade'
    results = described_class.execute(context)
    expect(
      results.section_student_scores.student_rows.map(&:student)
    ).to eq [student_1, student_3, student_2]
  end

  it 'sorts the students scores data by summative' do
    context_params[:sort_by] = 'summative'
    results = described_class.execute(context)
    expect(
      results.section_student_scores.student_rows.map(&:student)
    ).to eq [student_2, student_3, student_1]
  end

  it 'sorts the students scores data by formative' do
    context_params[:sort_by] = 'formative'
    results = described_class.execute(context)
    expect(
      results.section_student_scores.student_rows.map(&:student)
    ).to eq [student_3, student_1, student_2]
  end

  it 'sorts the students scores data by change' do
    context_params[:sort_by] = 'change'
    results = described_class.execute(context)
    expect(
      results.section_student_scores.student_rows.map(&:student)
    ).to eq [student_2, student_1, student_3]
  end
end
