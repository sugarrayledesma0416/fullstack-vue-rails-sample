require 'tasks/time_spent'

describe TimeSpent do
  describe '#fix_course' do
    it 'runs fix_section on each section in a course' do
      course = double(:course, sections: [111])
      allow(Course).to receive(:find).and_return(course)
      expect(TimeSpent).to receive(:fix_section).with(course.sections.first, false)
      TimeSpent.fix_course(1, false)
    end
  end

  describe '#fix_section' do
    let(:attempt) { create(:attempt, :time_spent => 7400) }

    before do
      allow(attempt).to receive(:time_limit).and_return(3800)
      allow(TimeSpent).to receive(:attempts).and_return([attempt])
    end

    it 'fixes the time_spent for each attempt in a section' do
      TimeSpent.fix_section(1, false)
      fixed_time_spent = 3800
      expect(attempt.time_spent).to eq(fixed_time_spent)
    end

    context 'when it is a dry run' do
      it 'does not save the attempt record' do
        expect(attempt).not_to receive(:save)
        TimeSpent.fix_section(1, true)
      end

      it 'does not propagate time spent to the score record' do
        expect(attempt).not_to receive(:propagate_time_spent_to_score)
        TimeSpent.fix_section(1, true)
      end
    end

    context 'when it is not a dry run' do
      it 'saves the attempt record' do
        expect(attempt).to receive(:save)
        TimeSpent.fix_section(1, false)
      end

      it 'propagates time spent to the score record for each attempt' do
        expect(attempt).to receive(:propagate_time_spent_to_score)
        TimeSpent.fix_section(1, false)
      end
    end
  end
end
