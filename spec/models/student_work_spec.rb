describe StudentWork do

  let(:student) { create(:student) }
  let(:section) { create(:section) }
  let(:activity) { create(:activity) }
  let!(:student_work) { StudentWork.new(student, section, [activity]) }


  describe '#prepare' do
    it 'returns a hash with activity keys and values of assignments, scores, and attempts' do
      assignment = create(:assignment, :assignable => activity)
      attempt = create(:attempt, :activity => activity)

      allow(Assignment).to receive(:by_section_and_activity).and_return([assignment])
      allow(Attempt).to receive(:by_student_section_and_activity).and_return([attempt])

      student_work.prepare
      expected = { activity => { assignment: assignment, attempts: [attempt] } }
      expect(student_work.work).to eql expected
    end
  end

  describe '#assignment_for' do
    it 'returns nil when there no activities' do
      expect(student_work.assignment_for(activity)).to be_nil
    end

    it 'returns the assignment for an activity' do
      assignment = build_stubbed(:assignment)
      allow(student_work).to receive(:work).and_return( { activity => { :assignment => assignment } } )
      expect(student_work.assignment_for(activity)).to eq(assignment)
    end
  end

  describe '#latest_attempt_for' do
    it 'returns nil when there are no attempts' do
      expect(student_work.latest_attempt_for(activity)).to be_nil
    end

    it 'returns the latest attempt for an activity' do
      attempt = build_stubbed(:attempt)
      allow(student_work).to receive(:work).and_return( { activity => { :attempts => [attempt] } } )
      expect(student_work.latest_attempt_for(activity)).to eq(attempt)
    end
  end
end
