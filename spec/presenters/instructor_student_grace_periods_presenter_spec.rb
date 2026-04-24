describe InstructorStudentGracePeriodsPresenter do
  let(:focus)         { double('Focus') }
  let(:program)       { create(:program) }
  let(:instructor)    { build_stubbed(:instructor) }
  let(:student)       { create(:student) }
  let(:course)        { create(:course, program_id: program.id) }
  let(:section)       { create(:section, course: course) }
  let(:grace_periods) { double('GracePeriodsCount', number_used: 0, number_allowed: 5, allowed?: true)}
  let!(:enrollment)   { create(:active_enrollment, section: section, user: student, sufficient_access: false) }
  let(:presenter) { InstructorStudentGracePeriodsPresenter.new(instructor, focus, program_id: program.id)}

  before do
    allow(focus).to receive(:sections).and_return([section])
    allow(focus).to receive(:course).and_return(course)
    allow(GracePeriodAllocation).to receive(:new).and_return(grace_periods)
    allow(Maestro::UserLicense).to receive(:all_for_user_and_program).and_return([])
    allow(Maestro::UserLicense).to receive(:all_for_users_in_program).and_return([])
  end

  describe "#students_with_access_problems" do
    it "returns an array of Student records" do
      students = presenter.students_with_access_problems
      expect(students).to be_a Array
      expect(students.first).to be_a Student
    end

    it "returns an empty array if grace periods are not allowed" do
      allow(grace_periods).to receive(:allowed?).and_return(false)
      students = presenter.students_with_access_problems
      expect(students).to be_empty
    end
  end

  describe "#students_with_grace_period" do
    let(:grace_period_license) { double('UserLicense', :grace_period? => true) }

    it "creates a list of students that have a grace period license for the course" do
      allow(presenter).to receive(:licenses_for_user).and_return([grace_period_license])
      students = presenter.students_with_grace_period
      expect(students).not_to be_empty
    end
  end

  describe "#filtered_students_with_access_problems" do
    let(:grace_period_license) { double('UserLicense', :grace_period? => true) }

    it "filters students that have been granted grace period access for the course" do
      allow(presenter).to receive(:licenses_for_user).and_return([grace_period_license])
      students = presenter.filtered_students_with_access_problems
      expect(students).to be_empty
    end

    it 'does not include students with enrollments as marked_complete' do
      marked_complete_enrollment = create(:completed_enrollment, section: section, sufficient_access: false)
      students = presenter.filtered_students_with_access_problems
      expect(students).not_to include marked_complete_enrollment.user_id
    end

    it 'does not include archived students' do
      other_enrollment = create(:active_enrollment, section: section, sufficient_access: false)
      other_enrollment.user.update!(archived: true)
      students = presenter.filtered_students_with_access_problems
      expect(students).not_to include other_enrollment.user_id
    end
  end

  describe "#has_grace_period_license?" do
    let(:grace_period_license) { double('UserLicense', :grace_period? => true) }

    it "returns true when the student has a grace period license" do
      allow(Maestro::UserLicense).to receive(:all_for_user_and_program).and_return([grace_period_license])
      expect(presenter.has_grace_period_license?(123)).to be_truthy
    end

    it "returns false when the student does not have a grace period license" do
      allow(Maestro::UserLicense).to receive(:all_for_user_and_program).and_return([])
      expect(presenter.has_grace_period_license?(123)).to be_falsey
    end
  end

  describe '#grace_period_days_remaning' do
    let(:expiration_in_days) { 30 }
    let(:grace_period_license) do
      instance_double(
        Maestro::UserLicense,
        grace_period?: true,
        expiration_date: expiration_in_days.days.from_now.to_date
      )
    end

    it 'returns nil, if student does not have grace periods' do
      allow(grace_period_license).to receive(:grace_period?).and_return(false)
      allow(Maestro::UserLicense).to receive(:all_for_user_and_program).and_return([grace_period_license])
      expect(presenter.grace_period_days_remaning(student.id)).to be_nil
    end

    it 'returns the remaining days of the grace period, if student has grace periods' do
      allow(Maestro::UserLicense).to receive(:all_for_user_and_program).and_return([grace_period_license])
      expect(presenter.grace_period_days_remaning(student.id)).to eq expiration_in_days
    end

    it 'returns zero, if the grace period has expired' do
      allow(grace_period_license).to receive(:expiration_date).and_return(15.days.ago.to_date)
      allow(Maestro::UserLicense).to receive(:all_for_user_and_program).and_return([grace_period_license])
      expect(presenter.grace_period_days_remaning(student.id)).to eq 0
    end
  end

  describe '#section_column_header' do
    context 'when the focus is a single section' do
      it 'returns the pluralized section count' do
        expect(presenter.section_column_header).to eq 'Section'
      end
    end

    context 'when the focus is the course and there are multiple sections' do
      before do
        other_section = create(:section, course:)
        allow(focus).to receive(:sections).and_return([section, other_section])
      end

      it 'returns the pluralized section count' do
        expect(presenter.section_column_header).to eq 'Sections'
      end
    end
  end
end
