require 'rails_helper'

RSpec.describe SectionPracticeTestAnalyzer do
  include RspecJsContentHelpers

  let(:activity) { create_summative_activity(program) }
  let(:course) { create(:course, program:) }
  let(:lesson) { create(:lesson) }
  let(:order) { 'asc' }
  let(:program) { lesson.unit.program }
  let(:results) do
    described_class.call(
      {
        lesson:,
        section:,
        order:,
        concept_id: study_plan_concept.id
      }
    )
  end
  let(:section) { create(:section, course:) }
  let(:student) { create(:student) }
  let(:student_scores) do
    [
      OpenStruct.new(
        user_id: student.id,
        formatted_submitted_not_due_score: 80,
        submitted?: true
      )
    ]
  end
  let(:study_plan_concept) do
    create(:study_plan_concept, program:, activity:, cms_revision_id: activity.cms_revision_id)
  end

  before do
    allow(FindLessonDiagnosticV2Activities).to receive(:lesson_has_summative_and_formative_activities?).and_return(true)
    allow(GradebookEngine::GradebookAPI).to receive(:find_section_assignment_grades).and_return(student_scores)
  end

  it 'sets concepts on the context' do
    expect(results.concepts).to eq []
  end

  it 'sets section_student_scores on the context' do
    expect(results.section_student_scores).to be_a(SectionAnalytics::PracticeTest::SectionStudentsAggregator)
  end

  it 'sets section_averages on the context' do
    expect(results.section_averages.first).to be_a(SectionAnalytics::PracticeTest::SectionConceptAverages)
  end

  it 'sets summative_average on the context' do
    expect(results.summative_average).to eq student_scores.first.formatted_submitted_not_due_score
  end

  it 'sets activities on the context' do
    expect(results.activities).to eq [activity]
  end

  it 'sets assignments on the context' do
    expect(results.assignments).to eq(formative: [], summative: nil)
  end
end
