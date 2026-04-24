describe InstructorAssignableActivity do
  class InstructorAssignableActivityClass
    include InstructorAssignableActivity
  end

  let(:mock_object){ InstructorAssignableActivityClass.new }
  let(:validator) { double('AssignmentValidator') }
  let(:user) { build_stubbed(:user) }
  let(:activities){ [build_stubbed(:activity)] }
  let(:course){ build_stubbed(:course) }

  before do
    allow(mock_object).to receive(:course).and_return(course)
    allow(mock_object).to receive(:activities).and_return(activities)
    allow(mock_object).to receive(:current_user).and_return(user)
  end

  describe '#assignment_validator' do
    it 'returns an assignment validator for the course and activities' do
      expect(AssignmentValidator).to receive(:new).with(user, course, activities).and_return(validator)
      expect(validator).to receive(:validate)
      expect(mock_object.assignment_validator).to eq(validator)
    end
  end

  describe '#activity_row_class' do
    let(:activity) { build_stubbed(:activity) }

    before do
      allow(mock_object).to receive(:assignment_validator).and_return(validator)
    end

    it 'returns unassignable_activity if the activity is unassignable' do
      expect(validator).to receive(:assignable?).with(activity).and_return(false)
      expect(mock_object.activity_row_class(activity)).to eq('unassignable_activity')
    end

    it 'returns an empty string if the activity is assignable' do
      expect(validator).to receive(:assignable?).with(activity).and_return(true)
      expect(mock_object.activity_row_class(activity)).to eq('')
    end
  end
end
