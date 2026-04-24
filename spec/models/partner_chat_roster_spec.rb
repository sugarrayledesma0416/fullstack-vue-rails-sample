describe PartnerChatRoster do
  let(:student_1) { create(:student)}
  let(:student_2) { create(:student)}
  let(:student_3) { create(:student)}
  let(:student_4) { create(:student)}
  let(:instructor) { create(:instructor)}
  let(:program) { create(:program)}

  let(:course) { create(:course, program: program )}
  let(:section) { create(:section, :course => course, instructor_id: instructor.id)}
  let(:section_2) { create(:section, :course => course, instructor_id: instructor.id)}
  let(:activity) { create(:activity)}

  describe "#roster" do
    context "when the user is a student" do
      before do
        create(:enrollment, :user => student_1, :section => section)
      end

      it "excludes the current user" do
        expect(PartnerChatRoster.new(student_1, section.course, activity).roster).to be_empty
      end

      it "when student has no attempts, returns the student with status code nil" do
        create(:enrollment, :user => student_2, :section => section)
        student_list = PartnerChatRoster.new(student_1, section.course, activity).roster
        expect(student_list.first.attempt_status_code).to be_nil
        expect(student_list.first.user_id).to eq(student_2.id)
      end

      it "when student has completed attempt, returns the student with status code completed" do
        create(:enrollment, :user => student_2, :section => section)
        create(:attempt, :user => student_2, :section => section, :activity => activity, :status_code => AttemptStatus::CODE_COMPLETED)
        student_list = PartnerChatRoster.new(student_1, section.course, activity).roster
        expect(student_list.first.attempt_status_code).to eq(AttemptStatus::CODE_COMPLETED)
        expect(student_list.first.user_id).to eq(student_2.id)
      end

      it "when student has submitted attempt, returns the student with status code nil" do
        create(:enrollment, :user => student_2, :section => section)
        create(:attempt, :user => student_2, :section => section, :activity => activity, :status_code => AttemptStatus::CODE_SUBMITTED)
        student_list = PartnerChatRoster.new(student_1, section.course, activity).roster
        expect(student_list.first.attempt_status_code).to be_nil
        expect(student_list.first.user_id).to eq(student_2.id)
      end

      it "when student has a reset attempt, returns the student with status code nil" do
        create(:enrollment, :user => student_2, :section => section)
        create(:attempt, :user => student_2, :section => section, :activity => activity, :status_code => AttemptStatus::CODE_RESET)
        student_list = PartnerChatRoster.new(student_1, section.course, activity).roster
        expect(student_list.first.attempt_status_code).to be_nil
        expect(student_list.first.user_id).to eq(student_2.id)
      end

      context "when the user is not in a course" do
        before do
          create(:enrollment, :user => student_1, :section => section)
        end

        it "returns an empty array" do
          expect(PartnerChatRoster.new(student_1, nil, activity).roster).to be_empty
        end
      end
    end

    context "when the user is an instructor" do
      it "returns the expected list of completed students" do
        create(:enrollment, :user => student_1, :section => section)
        create(:attempt, :user => student_1, :section => section, :activity => activity, :status_code => AttemptStatus::CODE_COMPLETED)
        create(:enrollment, :user => student_2, :section => section)
        create(:attempt, :user => student_2, :section => section, :activity => activity, :status_code => "not completed")
        allow(activity).to receive(:program).and_return(program)
        student_list = PartnerChatRoster.new(instructor, section.course, activity).roster
        completed_student = student_list.detect {|student| student.user_id == student_1.id}
        not_completed_student = student_list.detect {|student| student.user_id == student_2.id}
        expect(completed_student.attempt_status_code).to eq(AttemptStatus::CODE_COMPLETED)
        expect(not_completed_student.attempt_status_code).to be_nil
      end
    end
  end

  describe "#to_json" do
    it "returns a json" do
      pc_roster = PartnerChatRoster.new(student_1, section.course, activity)
      allow(pc_roster).to receive(:roster).and_return([])
      result = { 'students_complete' =>  [], 'students_incomplete' => [] }.to_json
      expect(pc_roster.to_json).to eq(result)
    end
  end

  describe "#students_complete" do
    it "when attempt is completed, returns array with student id " do
      other_student = double('Student', :attempt_status_code => AttemptStatus::CODE_COMPLETED, :user_id => 10)
      pc_roster = PartnerChatRoster.new(student_1, section.course, activity)
      allow(pc_roster).to receive(:roster).and_return([other_student])

      expect(pc_roster.students_complete).to eq([other_student.user_id])
    end

    it "when attempt is not completed, returns empty array" do
      other_student = double('Student', :attempt_status_code => nil , :user_id => 10)
      pc_roster = PartnerChatRoster.new(student_1, section.course, activity)
      allow(pc_roster).to receive(:roster).and_return([other_student])
      expect(pc_roster.students_complete).to eq([])
    end
  end

  describe "#students_incomplete" do
    it "when attempt is completed, returns an empty array" do
      other_student = double('Student', :attempt_status_code => AttemptStatus::CODE_COMPLETED, :user_id => 10)
      pc_roster = PartnerChatRoster.new(student_1, section.course, activity)
      allow(pc_roster).to receive(:roster).and_return([other_student])

      expect(pc_roster.students_incomplete).to eq([])
    end

    it "when attempt is not completed, returns array with student id" do
      other_student = double('Student', :attempt_status_code => nil , :user_id => 10)
      pc_roster = PartnerChatRoster.new(student_1, section.course, activity)
      allow(pc_roster).to receive(:roster).and_return([other_student])
      expect(pc_roster.students_incomplete).to eq([other_student.user_id])
    end

    context "when attempts include reset attempts, and the latest attempt is not completed" do
      it "returns array with user_id and without duplicates" do
        student_at_1 = double('Student', :attempt_status_code => nil , :user_id => 10)
        student_at_2 = double('Student', :attempt_status_code => nil , :user_id => 10)
        pc_roster = PartnerChatRoster.new(student_1, section.course, activity)
        allow(pc_roster).to receive(:roster).and_return([student_at_1,student_at_2])
        expect(pc_roster.students_incomplete).to eq([student_at_1.user_id])
      end
    end

    context "when attempts include reset attempts, and the latest attempt is completed" do
      it "returns empty array" do
        student_at_1 = double('Student', :attempt_status_code => nil , :user_id => 10)
        student_at_2 = double('Student', :attempt_status_code => AttemptStatus::CODE_COMPLETED, :user_id => 10)
        pc_roster = PartnerChatRoster.new(student_1, section.course, activity)
        allow(pc_roster).to receive(:roster).and_return([student_at_1,student_at_2])
        expect(pc_roster.students_incomplete).to eq([])
      end
    end
  end
end
