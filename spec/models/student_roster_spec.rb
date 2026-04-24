describe StudentRoster do
  let(:student_1) { build_stubbed(:student) }
  let(:student_2) { build_stubbed(:student) }
  let(:section_1) { build_stubbed(:section) }
  let(:section_2) { build_stubbed(:section) }
  let(:enrollment_1) { build_stubbed(:enrollment, :user => student_1, :section => section_1)}
  let(:enrollment_2) { build_stubbed(:enrollment, :user => student_2, :section => section_2)}
  let(:student_roster) { StudentRoster.new([student_1, student_2], [section_1, section_2]) }

  describe "#section_for_student" do
    before do
      allow(Enrollment).to receive(:find_all_active_or_completed_by_users_and_sections).and_return([enrollment_1, enrollment_2])
    end

    it "returns the section that the student is enrolled in" do
      expect(student_roster.section_for_student(student_1)).to eq(section_1)
      expect(student_roster.section_for_student(student_2)).to eq(section_2)
    end

    it "returns nil if the student is not part of the list" do
      expect(student_roster.section_for_student(build_stubbed(:student))).to be_nil
    end
  end

  describe "#enrollment_for_student" do
    before do
      allow(Enrollment).to receive(:find_all_active_or_completed_by_users_and_sections).and_return([enrollment_1, enrollment_2])
    end

    it "returns the enrollment record for the student" do
      expect(student_roster.enrollment_for_student(student_1)).to eq(enrollment_1)
      expect(student_roster.enrollment_for_student(student_2)).to eq(enrollment_2)
    end

    it "returns nil if the student is not part of the list" do
      expect(student_roster.enrollment_for_student(build_stubbed(:student))).to be_nil
    end
  end

  describe "#students_in_section" do
    before do
      allow(Enrollment).to receive(:find_all_active_or_completed_by_users_and_sections).and_return([enrollment_1, enrollment_2])
    end

    it "returns an array of students enrolled in the section" do
      expect(student_roster.students_in_section(section_1)).to eq([student_1])
      expect(student_roster.students_in_section(section_2)).to eq([student_2])
    end

    it "returns nil if the wrong section if passed" do
      expect(student_roster.students_in_section(build_stubbed(:section))).to be_nil
    end
  end
end
