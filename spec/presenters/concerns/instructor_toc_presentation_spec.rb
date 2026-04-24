describe InstructorTocPresentation do
  let(:course) { create(:course, program: program, owner_id: user.id) }
  let(:program) { create(:program) }
  let(:section) { create(:section, course: course, instructor: user) }
  let(:user) { create(:instructor) }

  let(:presenter_klass) do
    Class.new do
      include Rails.application.routes.url_helpers
      # "Common" means shared between Supersite Junior and non-Supersite Junior
      include TocPresenterCommon
      # "Standard" means "not Supersite Junior"
      include StandardTocPresentation
      include StudentTocPresentation
      include InstructorTocPresentation

      attr_accessor :program, :target_sections

      def initialize(user, program, target_sections, base_url)
        self.program = program
        self.current_user = user
        self.target_sections = target_sections
        @base_url = base_url
      end

      def base_url(options = {})
        @base_url
      end

      def current_focus
        return @current_focus if defined? @current_focus

        target_id = if target_sections.size == 1
                      { 'section_id' => target_sections.first.id }
                    else
                      { 'course_id' => target_sections.first.course_id }
                    end

        options = { program.id.to_s => target_id }
        @current_focus = Focus.new(current_user, program, options)
      end
    end
  end

  before do
    allow_any_instance_of(AccessGuardian).to receive(:has_unexpired_demo_access?).and_return(true)
  end

  let(:presenter) { presenter_klass.new(user, program, [section], 'base url') }

  describe '#assignments' do
    let(:lesson) { create(:lesson, toc_entries: [strand], unit: unit) }
    let(:program) { create(:program) }
    let(:strand) { create(:toc_entry) }
    let(:unit) { create(:unit, program: program) }
    let(:concept) { create(:concept, lesson: lesson, program: program) }
    let(:section_1) { section }
    let(:section_2) { create(:section, course: course, instructor: user) }
    let(:other_course_section) { create(:section, instructor: user) }
    let(:presenter) do
      presenter_klass.new(user, program, [section_1, section_2], 'base url')
    end

    def create_activity
      create(
        :activity,
        concept: concept,
        lesson: lesson,
        toc_location: strand.location
      )
    end

    it 'returns only assignments for the specified activities in the ' \
       'currently focused sections' do
      activity_1 = create_activity
      activity_2 = create_activity
      activity_3 = create_activity
      other_section_activity = create_activity

      section_1_assignment_1 = create(
        :assignment,
        assignable: activity_1,
        section: section_1
      )

      section_1_assignment_2 = create(
        :assignment,
        assignable: activity_2,
        section: section_1
      )

      section_2_assignment_1 = create(
        :assignment,
        assignable: activity_1,
        section: section_2
      )

      section_2_assignment_2 = create(
        :assignment,
        assignable: activity_3,
        section: section_2
      )

      # Assigned, but in a section that is not currently focused.
      create(
        :assignment,
        assignable: other_section_activity,
        section: other_course_section
      )

      # Assigned in a focused section, but not one of the activities
      # for the current strand.
      other_lesson_activity = create(
        :activity,
        lesson: create(:lesson),
        toc_location: create(:toc_entry).location
      )
      create(:assignment, assignable: other_lesson_activity, section: section_1)

      expect(presenter.assignments).to contain_exactly(
        section_1_assignment_1,
        section_1_assignment_2,
        section_2_assignment_1,
        section_2_assignment_2
      )
    end

    context 'when there are individual due dates for an assignment' do
      let(:activity_1) { create_activity }
      let(:activity_2) { create_activity }

      let(:section_1_assignment_1) do
        create(
          :assignment,
          assignable: activity_1,
          individually_assignable: true,
          section: section_1
        )
      end

      let(:section_1_assignment_2) do
        create(
          :assignment,
          assignable: activity_2,
          individually_assignable: true,
          section: section_1
        )
      end

      it 'returns a multiple due dates attribute set to true if dates differ ' \
         'from default due date and assignment is individually assignable' do
        IndividualAssignment.create!(
          activity_id: activity_1.id,
          due_date: section_1_assignment_1.due_date + 1,
          section_id: section_1.id,
          user_id: create(:student).id
        )

        expect(
          presenter.assignments.map { |a| [a.assignable_id, a.multiple_due_dates?] }
        ).to eq([[activity_1.id, true]])
      end

      it 'returns a multiple due dates attribute set to false if there are ' \
         'no individual assignments for the activity' do
        section_1_assignment_2

        expect(
          presenter.assignments.map { |a| [a.assignable_id, a.multiple_due_dates?] }
        ).to eq([[activity_2.id, false]])
      end

      it 'returns a multiple due dates attribute set to false if individual ' \
         'assignments for the activity do not override default due date' do
        section_1_assignment_2

        IndividualAssignment.create!(
          activity_id: activity_2.id,
          section_id: section_1.id,
          user_id: create(:student).id
        )

        expect(
          presenter.assignments.map { |a| [a.assignable_id, a.multiple_due_dates?] }
        ).to eq([[activity_2.id, false]])
      end

      it 'returns a multiple due dates attribute set to false if dates are ' \
         'same as default due date' do
        IndividualAssignment.create!(
          activity_id: activity_1.id,
          due_date: section_1_assignment_1.due_date,
          section_id: section_1.id,
          user_id: create(:student).id
        )

        expect(
          presenter.assignments.map { |a| [a.assignable_id, a.multiple_due_dates?] }
        ).to eq([[activity_1.id, false]])
      end

      it 'returns a multiple due dates attribute set to false if assignment ' \
         'is not individually assignable' do
        IndividualAssignment.create!(
          activity_id: activity_1.id,
          due_date: section_1_assignment_1.due_date + 1,
          section_id: section_1.id,
          user_id: create(:student).id
        )

        section_1_assignment_1.individually_assignable = false
        section_1_assignment_1.save!

        expect(
          presenter.assignments.map { |a| [a.assignable_id, a.multiple_due_dates?] }
        ).to eq([[activity_1.id, false]])
      end
    end
  end

  describe '#activity_creator' do
    let(:institution_admin) { create(:instructor) }
    let(:lesson) { create(:lesson, toc_entries: [strand], unit: unit) }
    let(:program) { create(:program) }
    let(:school) { create(:school) }
    let(:strand) { create(:toc_entry) }
    let(:unit) { create(:unit, program: program) }

    let(:igc_activity) do
      create(
        :instructor_created_activity,
        lesson: lesson,
        toc_entry_id: strand.location,
        instructor: institution_admin
      )
    end

    let(:shared_library_activity) do
      create(
        :shared_library_activity,
        source_activity: igc_activity,
        activity: igc_activity,
        school: school,
        institution_admin_approver_id: institution_admin.id
      )
    end

    before do
      create(:concept, lesson: lesson, program: program, id: strand.location)
      allow(Maestro::LicenseGroup).to receive(:all).and_return(
        [instance_double(Maestro::LicenseGroup, id: 1, name: '01-Supersite')]
      )
    end

    it 'returns the instructor username' do
      shared_library_activity
      expect(presenter.activity_creator(igc_activity)).to eq(institution_admin.full_name)
    end
  end

  describe '#allowed_to_create_content?' do
    context 'when the user is the owner of the current course focus' do
      it 'returns true' do
        expect(presenter).to be_allowed_to_create_content
      end
    end

    context 'when the user is not the owner of the current course focus' do
      let(:other_instructor) { create(:instructor) }
      let(:presenter) do
        presenter_klass.new(other_instructor, program, [section], 'base url')
      end

      let!(:section_instructor) do
        create(:section_instructor, user_id: other_instructor.id, section: section)
      end

      context 'when the user is allowed to edit content ' \
              'for all sections in the current course focus' do
        it 'returns true' do
          expect(presenter).to be_allowed_to_create_content
        end
      end

      context 'when the user is not allowed to edit content ' \
              'for all sections in the current course focus' do
        it 'returns false' do
          section_instructor.allowed_to_edit_content = false
          section_instructor.save!
          expect(presenter).not_to be_allowed_to_create_content
        end
      end
    end
  end

  describe '#other_instructor_activity?' do
    let(:instructor) { create(:instructor) }
    let(:my_activity) { create(:activity, instructor_id: user) }
    let(:others_activity) { create(:activity, instructor_id: other_instructor) }
    let(:other_instructor) { create(:instructor) }

    context 'when activity does not have instructor_id,' do
      it 'returns false' do
        presenter.current_user = nil
        allow(my_activity).to receive(:instructor_id).and_return(nil)
        expect(presenter.other_instructor_activity?(my_activity)).to be_falsey
      end
    end

    context 'when activity was created by current user,' do
      it 'returns false' do
        presenter.current_user = instructor
        allow(my_activity).to receive(:instructor_id).and_return(instructor.id)
        expect(presenter.other_instructor_activity?(my_activity)).to be_falsey
      end
    end

    context 'when activity was created by other instructor,' do
      it 'returns true' do
        allow(others_activity).to receive(:instructor_id).and_return(other_instructor.id)
        expect(presenter.other_instructor_activity?(others_activity)).to be_truthy
      end
    end
  end
end
