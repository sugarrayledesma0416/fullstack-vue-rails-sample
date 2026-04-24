describe GradingTasksHelper do
  include GradingTasksHelper
  describe '#format_lesson_strand_label' do
    it 'has specs', test_debt: true do
      skip
    end
  end

  describe '#format_grading_count' do
    let(:number_graded) { 1 }

    context 'when in the Already Graded section' do
      it "says 'x already graded'" do
        task_type = 'already_graded_section'
        expect(format_grading_count(number_graded, task_type)).to eql '1 already graded'
      end
    end

    context 'when in Needs Grading, Upcoming Grading, or Unassigned' do
      it "says 'x to be graded'" do
        task_type = 'needs_grading_section'
        expect(format_grading_count(number_graded, task_type)).to eql '1 to be graded'
      end
    end
  end

  describe '#format_submitted_count' do
    let(:submissions_counts) do
      { assigned_count: 5, submitted_count: 3 }
    end

    context 'when in the Unassigned activities section' do
      it "says 'x submitted'" do
        task_type = 'unassigned_activities_section'
        expect(format_submitted_count(submissions_counts, task_type)).to eql '3 submitted'
      end
    end

    context 'when in Needs Grading, Upcoming Grading, or Already Graded' do
      it "says 'x submitted of x'" do
        task_type = 'needs_grading_section'
        expect(format_submitted_count(submissions_counts, task_type)).to eql '3 of 5 submitted'
      end
    end
  end
end
