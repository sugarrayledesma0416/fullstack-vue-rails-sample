describe AssignedAssessmentDetail do
  it 'is invalid if time limit is not a positive number' do
    assigned_assessment_detail = build(:assigned_assessment_detail, time_limit: -1)
    expect(assigned_assessment_detail).not_to be_valid
  end

  it 'is invalid if time limit is 1' do
    assigned_assessment_detail = build(:assigned_assessment_detail, time_limit: 1)
    expect(assigned_assessment_detail).not_to be_valid
  end

  it 'is valid if time limit is 0' do
    assigned_assessment_detail = build(:assigned_assessment_detail, time_limit: 0)
    expect(assigned_assessment_detail).to be_valid
  end

  describe '#strip_password' do
    it 'strips leading and trailing whitespace from a password' do
      assigned_assessment_detail = create(:assigned_assessment_detail)
      assigned_assessment_detail.password = ' one two '
      assigned_assessment_detail.strip_password
      expect(assigned_assessment_detail.password).to eql 'one two'
    end
  end

  describe '#time_limit' do
    it 'returns 0 if time limit is nil' do
      assigned_assessment_detail = create(:assigned_assessment_detail, time_limit: nil)
      expect(assigned_assessment_detail.time_limit).to eq(0)
    end

    it 'returns the given value if it is not nil' do
      assigned_assessment_detail = create(:assigned_assessment_detail, time_limit: 50)
      expect(assigned_assessment_detail.time_limit).to eq(50)
    end
  end
end
