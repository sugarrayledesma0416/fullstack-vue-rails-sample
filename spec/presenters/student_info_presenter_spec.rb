describe StudentInfoPresenter do

  let(:student) { build_stubbed(:student) }
  let(:program) { build_stubbed(:program) }
  let(:section) { build_stubbed(:section) }
  let(:enrollment) { build_stubbed(:enrollment, :section => section, :user => student, :state => 'enrolled') }
  let(:presenter) { StudentInfoPresenter.new(student, program, section) }

  before do
    allow(Enrollment).to receive(:by_section_and_student).and_return([enrollment])
  end

  describe '#student_full_name' do
    it "returns the student's full name" do
      expect(presenter.student_full_name).to eq(student.full_name)
    end
  end

  describe '#section' do
    it 'returns the section the student belongs to for the program if not passed in' do
      presenter = StudentInfoPresenter.new(student, program, nil)
      expect(presenter.student).to receive(:current_section_in_program).with(program).and_return(section)
      presenter.section
    end
  end

  describe '#section_name' do
    context "when enrolled" do
      it 'returns the section name' do
        section = build_stubbed(:section)
        allow(presenter).to receive(:section).and_return(section)
        expect(presenter.section_name).to eq(section.name)
      end
    end

    context "when marked_complete" do
      let(:enrollment) { build_stubbed(:enrollment, :section => section, :user => student, :state => 'marked_complete') }

      it "returns a completed status along with the section name" do
        section = build_stubbed(:section)
        allow(Enrollment).to receive(:by_section_and_student).and_return([enrollment])
        allow(presenter).to receive(:section).and_return(section)
        expect(presenter.section_name).to eq("#{section.name} (completed)")
      end
    end
  end

  describe "#enrollment" do
    it "returns the student enrollment for the section" do
      expect(Enrollment).to receive(:by_section_and_student).and_return([enrollment])
      expect(presenter.enrollment).to eql enrollment
    end
  end

  describe '#course_name' do
    it 'returns the name of the course the student is in' do
      allow(presenter).to receive(:section).and_return(build_stubbed(:section))
      expect(presenter.section).to receive(:course_name).and_return("course")
      expect(presenter.course_name).to eq("course")
    end
  end

  describe '#thumbnail_path' do
    it 'initializes a new Avatar with the current student, and returns the thumbnail path of that avatar' do
      expect(presenter.thumbnail_path).to eql student.avatar_thumb_url
    end

  end
end
