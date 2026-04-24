describe StudentTocPresentation do
  let(:course) { create(:course, program: program, owner_id: instructor.id) }
  let(:program) { create(:program) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:instructor) { create(:instructor) }
  let(:student) { create(:user) }
  let(:enrollment) { create(:enrollment, section: section, user: student) }

  let(:presenter_klass) do
    Class.new do
      include Rails.application.routes.url_helpers
      # "Common" means shared between Supersite Junior and non-Supersite Junior
      include TocPresenterCommon
      # "Standard" means "not Supersite Junior"
      include StandardTocPresentation
      include StudentTocPresentation

      attr_accessor :current_user, :program, :section

      def initialize(program, student, section)
        self.current_user = student
        self.program = program
        self.section = section
      end
    end
  end

  describe '#sections' do
    it 'returns an array containing the section' do
      presenter = presenter_klass.new(program, student, section)
      expect(presenter.sections).to eq([section])
    end
  end

  describe '#assignments' do
    def create_activity
      create(
        :activity,
        concept: concept,
        lesson: lesson,
        toc_location: strand.location
      )
    end

    let(:lesson) { create(:lesson, toc_entries: [strand], unit: unit) }
    let(:program) { create(:program) }
    let(:strand) { create(:toc_entry) }
    let(:unit) { create(:unit, program: program) }
    let(:concept) { create(:concept, lesson: lesson, program: program) }
    let(:section_1) { section }
    let(:presenter) { presenter_klass.new(program, student, section) }
    let(:activity_1) { create_activity }

    let(:section_1_assignment_1) do
      create(
        :assignment,
        assignable: activity_1,
        section: section_1
      )
    end

    it 'returns custom due date if individual assignment overrides default' do
      create(:individual_assignment,
             activity_id: activity_1.id,
             due_date: section_1_assignment_1.due_date + 7.days,
             section_id: section_1.id,
             user_id: student.id)

      expect(presenter.assignments[0].due_date).to eq(section_1_assignment_1.due_date + 7.days)
    end

    it 'returns default due date if individual_assignment does not set a custom date' do
      section_1_assignment_1

      create(:individual_assignment,
             activity_id: activity_1.id,
             due_date: nil,
             section_id: section_1.id,
             user_id: student.id)

      expect(presenter.assignments[0].due_date).to eq(section_1_assignment_1.due_date)
    end
  end
end
