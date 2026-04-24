describe StudentByStudentViewManager do
  let(:presenter){ double('Presenter').as_null_object }
  let(:view_manager){ StudentByStudentViewManager.new(presenter) }

  describe "#language" do
    it "returns the language of the activity" do
      allow(presenter).to receive_message_chain(:activity, :content_object, :language).and_return('test language')
      expect(view_manager.language).to eql 'test language'
    end
  end

  describe "#has_mixed_grading_method?" do
    it "returns whether the activity is a multi-type or not" do
      expect(presenter.activity).to receive(:has_mixed_grading_method?)
      view_manager.has_mixed_grading_method?
    end
  end

  describe "#recording_activity?" do
    it "returns whether the activity is a recording activity or not" do
      expect(presenter.activity).to receive(:recording_activity?)
      view_manager.recording_activity?
    end
  end

  describe "#activity_references" do
    it "returns the references for the activity" do
      ref1 = double('MaestroActivityEngine::ActivityContent::Reference::Base', :is_a? => true)
      ref2 = double('MaestroActivityEngine::ActivityContent', :is_a? => false)
      allow(presenter).to receive_message_chain(:activity, :content_object, :references).and_return([ref1, ref2])
      expect(view_manager.activity_references).to eql [ref1]
    end
  end

  describe "#currently_on_first_student?" do
    it "returns true if the current student is the first student in the grading set" do
      allow(presenter).to receive(:current_student).and_return('current_student')
      allow(presenter).to receive(:students_to_grade).and_return(['current_student', 'last_student'])
      expect(view_manager.currently_on_first_student?).to be_truthy
    end
  end

  describe "#currently_on_last_student?" do
    it "returns true if the current student is the last student in the grading set" do
      allow(presenter).to receive(:current_student).and_return('current_student')
      allow(presenter).to receive(:students_to_grade).and_return(['first_student', 'current_student'])
      expect(view_manager.currently_on_last_student?).to be_truthy
    end
  end

  describe "#graded?" do
    let(:student) { double('student') }

    before(:each) do
      allow(view_manager).to receive(:students_with_pending_grade).and_return(double('students_with_pending_grade'))
      allow(view_manager.students_with_pending_grade).to receive(:exclude?) do |id|
        ![1, 2].include?(id)
      end
    end

    it "returns true when student is not among students with pending grade" do
      allow(student).to receive(:id).and_return(3)
      expect(view_manager.graded?(student)).to be_truthy
    end

    it "returns false when student is among students with pending grade" do
      allow(student).to receive(:id).and_return(2)
      expect(view_manager.graded?(student)).to be_falsey
    end
  end

  describe "#option_string" do
    it "returns expected value" do
      student = double('student')
      allow(student).to receive(:id).and_return(1)
      expect(view_manager.option_string(student)).to eq "#1"
    end
  end

  describe "#option_value" do
    it "returns expected value" do
      student = double('student')
      allow(student).to receive(:id).and_return(1)
      expect(view_manager.option_value(student)).to eq 1
    end
  end

  describe "#option_jump_to" do
    it "returns the same value as #option_value" do
      student = double('student')
      allow(student).to receive(:id).and_return(1)
      expect(view_manager.option_jump_to(student)).to eq view_manager.option_value(student)
    end
  end

  describe "#option_data" do
    it "returns expected value" do
      student = double('student')
      allow(student).to receive(:full_name).and_return('Foo Bar')
      allow(student).to receive(:id).and_return(1)
      expect(view_manager.option_data(student)).to eq({
        student_name: 'Foo Bar',
        student_number: '#1'
      })
    end
  end
end
