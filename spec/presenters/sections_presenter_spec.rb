describe SectionsPresenter do
  let(:params){ { course_id: 1, id: 2 } }
  let(:current_user){ build_stubbed(:instructor)}
  let(:current_program){ build_stubbed(:program)}
  let(:section){ build_stubbed(:section, instructor: current_user ) }
  let(:presenter){ SectionsPresenter.new(current_user, current_program, params) }

  describe "#course" do
    it "finds the course specified in the params" do
      including_templates = double('including templates')
      allow(Course).to receive(:including_templates).and_return(including_templates)
      expect(including_templates).to receive(:find).with(params[:course_id])
      presenter.course
    end
  end

  describe "#section" do
    context "when in editing a section" do
     it "finds the section specified in the params" do
        expect(Section).to receive(:find).with(params[:id])
        presenter.section
      end
    end

    context "when creating a section" do
      let(:params){ { course_id: 1 } }
      let(:presenter) { SectionsPresenter.new(current_user, current_program, params) }

      it "makes a new section in memory" do
        allow(presenter).to receive(:course).and_return(build_stubbed(:course, id: 1))
        expect(Section).to receive(:new).with(
          { instructor_id: current_user.id, course_id: params[:course_id] }
        )
        presenter.section
      end
    end
  end

  describe "#previous_sections_for_course" do
    let(:course) { create(:course, owner: current_user) }
    let(:section) { create(:section, course: course, instructor: current_user) }
    let(:params) { { course_id: course.id } }
    let(:additional_course) { create(:course, owner: current_user) }
    let(:additional_section) { create(:section, course: additional_course, instructor: current_user) }
    it "returns only the section associated with this course" do
      expect(presenter.previous_sections_for_course).to match_array([section])
    end
  end

  describe "#build_additional_instructors" do
    before do
      allow(presenter).to receive(:section).and_return(section)
      allow(section).to receive(:prospective_additional_instructors).and_return([])
    end

    it "fetches a list of prospective instructors from the section" do
      expect(section).to receive(:prospective_additional_instructors)
      presenter.build_additional_instructors
    end

    it "builds the section instructor for the current user unless it already exists" do
      expect(presenter.section.section_instructors).to eq []
      presenter.build_additional_instructors
      expect(presenter.section.section_instructors.first.user_id).to eq current_user.id
    end

    it "builds section instructors for any prospective instructors" do
      additional_instructor = build_stubbed(:instructor)
      allow(section).to receive(:prospective_additional_instructors).and_return([additional_instructor])
      presenter.build_additional_instructors
      expect(presenter.section.section_instructors.map(&:user_id)).to include(additional_instructor.id)
    end
  end
end
