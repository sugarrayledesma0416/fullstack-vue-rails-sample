describe ActivityAssignment, core: true do
  let!(:program) { create(:program) }

  before do
    school    = build_stubbed(:school)
    @owner    = build_stubbed(:instructor)
    @course   = create(:course, owner: @owner, program: program, school: school)
    @section  = create(:section, course: @course , instructor: @course.owner)
    @activity = create(:activity)
  end

  it "raises an error if neither a section id or course id parameter is passed" do
    expected_error = "must provide either :section_id or :course_id"
    expect{ ActivityAssignment.new(@activity, @owner, program) }.to raise_error expected_error
  end

  context "when initialized with a section id," do
    it "finds and populates assignments for the given activity and the section with that id" do
      expect(Assignment).to receive(:activity_assignments).with([@section], [@activity]).and_return(['valid_assignments'])
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)

      expect(activity_assignment.assignments).to eql ['valid_assignments']
    end
  end

  context "when initialized with a course id," do
    it "finds and populates assignments for the given activity and all sections with that course id" do
      section_2 = create(:section, :course => @course, :instructor => @course.owner)
      expect(Assignment).to receive(:activity_assignments).with([@section, section_2], [@activity]).and_return(['valid_assignments'])
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)

      expect(activity_assignment.assignments).to eql ['valid_assignments']
    end
  end

  describe "#assign_or_update" do

    before(:each) do
      @category = create(:category)
    end

    it "returns false and sets an error message on due_date when due date is blank" do
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
      expect(activity_assignment.assign_or_update(:due_date => '', :category_id => @category.id)).to be_falsey
      expect(activity_assignment.errors[:due_date]).to eq(['is required.'])
    end

    it "returns false and sets an error message on due_date when due date is not a valid date" do
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
      expect(activity_assignment.assign_or_update(:due_date => '1234', :category_id => @category.id)).to be_falsey
      expect(activity_assignment.errors[:due_date]).to eq(['must be a valid date.'])
    end

    it "returns false and sets an error message on due_date when due date is before the course start date" do
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
      due_date = @course.start_date - 1
      expect(activity_assignment.assign_or_update(:due_date => due_date, :category_id => @category.id)).to be_falsey
      expect(activity_assignment.errors[:due_date]).to eq(["must be after course start date, which is #{@course.start_date.strftime('%m/%d/%Y')}"])
    end

    it "returns false and sets an error message on due_date when due date is after the course end date" do
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
      due_date = @course.end_date + 1
      expect(activity_assignment.assign_or_update(:due_date => due_date, :category_id => @category.id)).to be_falsey
      expect(activity_assignment.errors[:due_date]).to eq(["must be before course end date, which is #{@course.end_date.strftime('%m/%d/%Y')}"])
    end

    it "returns false and sets an error message on base when category_id is blank" do
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
      activity_assignment.assign_or_update(:category_id => nil)
      expect(activity_assignment.errors[:base]).to eq(['Please select a category.'])
    end

    context "when an assignment already exists for one of the sections for the activity_assignment," do
      let(:new_category_id) { create(:category).id }

      it "should call update_assignment" do
        assignment = create(:assignment, :assignable => @activity, :section => @section,
                                          :category => @category, :due_date => @course.start_date + 1)

        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
        allow(activity_assignment).to receive(:assignments).and_return([assignment])

        new_due_date = assignment.due_date + 7

        expect(Assignment).to receive(:update_assignment)
        activity_assignment.assign_or_update(:due_date => new_due_date.strftime('%m/%d/%Y'), :category_id => new_category_id)

      end

      it "should set the due date and category of that assignment to the specified params" do
        assignment = create(:assignment, :assignable => @activity, :section => @section,
                                          :category => @category, :due_date => @course.start_date + 1, :rank => 2)

        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)

        new_due_date = assignment.due_date + 7

        activity_assignment.assign_or_update(:due_date => new_due_date.strftime('%m/%d/%Y'), :category_id => new_category_id)

        assignment = Assignment.where(due_date: new_due_date, category_id: new_category_id).first
        expect(assignment.category_id).to eql new_category_id
        expect(assignment.due_date).to eql new_due_date
        expect(assignment.rank).to eql(1)
      end
    end

    context 'when no assignment already exists for one of the sections ' \
            'for the activity_assignment,' do
      before do
        @due_date = Date.today + 1
        @category_id = @category.id
        @lesson = create(:lesson)
        unit = create(:unit, program: program, lessons: [@lesson])
        @activity = create(:activity, lesson: @lesson)
        @toc_entry = create(:toc_entry)
        allow(@activity).to receive(:lesson).and_return(@lesson)
        allow(@activity).to receive(:program).and_return(program)
        allow(@lesson).to receive(:strand_for_toc_location).and_return(@toc_entry)
        allow(Week).to receive(:week_containing).and_return(1.days.from_now.beginning_of_week.to_date)
        @activity_assignment = described_class.new(
          @activity,
          @owner,
          program,
          section_id: @section.id
        )
      end

      it 'creates a new assignment for that section with the specified due date and category' do
        @activity_assignment.assign_or_update(
          due_date: @due_date.strftime('%m/%d/%Y'),
          category_id: @category_id
        )
        assignment = Assignment.where(due_date: @due_date, category_id: @category_id).first
        expect(assignment.rank).to eq(1)
        expect(assignment).to be_a Assignment
      end

      context 'when there is an assignment set for the same due date and section' do
        let(:previous_assignment) { create(:assignment, section: @section) }

        let(:assignment_set_1) do
          create(
            :assignment_set,
            section: @section,
            due_date: @due_date.strftime('%m/%d/%Y')
          )
        end

        before do
          create(
            :assignment_set_activity,
            activity: Activity.find(previous_assignment.assignable_id),
            assignment_set: assignment_set_1,
            assignment_set_rank: 1
          )
        end

        it 'creates a assignment set activity record for the new assignment' do
          @activity_assignment.assign_or_update(
            due_date: @due_date.strftime('%m/%d/%Y'),
            category_id: @category_id
          )

          new_assignment = Assignment.find_by(due_date: @due_date, category_id: @category_id)

          expect(
            AssignmentSetActivity.where(activity_id: new_assignment.assignable_id).count
          ).to eq(1)
        end
      end
    end

    context 'course library activities' do
      context 'without errors' do
        let (:today) { Date.today + 1 }
        it 'makes a call to unhide the activity from the course' do
          expect(CourseLibraryActivity).to receive(:unhide_activity).with(@activity.id, @course.id)
          activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
          activity_assignment.assign_or_update(:due_date => today.strftime("%m/%d/%Y"), :category_id => @category.id)
        end
      end

      context 'with errors' do
        it 'does not make a call to unhide the activity from the course' do
          expect(CourseLibraryActivity).not_to receive(:unhide_activity)
          activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
          activity_assignment.assign_or_update(:due_date => '', :category_id => @category.id)
        end
      end
    end

    context 'when assigned activity is of type group chat' do
      let(:today) { Date.today + 1 }
      let(:group_chat_activity) { create(:activity, activity_type: 'group_chat') }
      let(:activity_assignment) do
        ActivityAssignment.new(
          group_chat_activity,
          @owner,
          program,
          section_id: @section.id
        )
      end
      let(:controller_params) do
        ActionController::Parameters.new({
          due_date: today.strftime("%m/%d/%Y"),
          category_id: @category.id,
          group_minimum: 4,
          group_maximum: 5
        })
      end

      it 'configures the group chat minimum and maximum value' do
        activity_assignment.assign_or_update(controller_params)
        assignment = Assignment.where(
          due_date: today.strftime("%m/%d/%Y"),
          category_id: @category.id
        ).first

        expect(assignment.group_chat_assignment_config.group_minimum).to eql(4)
        expect(assignment.group_chat_assignment_config.group_maximum).to eql(5)
      end

      it 'does not fail if the group_minimum and group_maximum params are not present' do
        expect {
          activity_assignment.assign_or_update(controller_params.except(:group_minimum, :group_maximum))
        }.not_to raise_error
        assignment = Assignment.where(
          due_date: today.strftime("%m/%d/%Y"),
          category_id: @category.id
        ).first
        expect(assignment.group_chat_assignment_config).to be_nil
      end
    end
  end

  describe "#unassign" do
    let(:category) { build_stubbed(:category) }

    before do
      @assignment = create(
                      :assignment,
                      assignable: @activity,
                      section: @section,
                      category: category,
                      due_date: @course.start_date + 1
                    )
    end

    context "when the activity assignment has assignments," do
      it "deletes the assignment" do
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, section_id: @section.id)

        activity_assignment.assignments.each do |assignment|
          expect(assignment).to receive(:destroy)
        end

        activity_assignment.unassign
      end
    end

    context 'when the assignment is a timed assessment' do
      it 'deletes the associated student time limit records' do
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, section_id: @section.id)

        activity_assignment.assignments.each do |assignment|
          allow(assignment).to receive(:assessment?).and_return(true)
          allow(assignment).to receive(:time_limit).and_return(60)
          expect(assignment).to receive(:destroy)
        end

        expect(AssessmentStudentTimeLimit)
          .to receive(:delete_time_limits)
          .with(@section.id, @activity.id)

        activity_assignment.unassign
      end
    end

    context 'when the assignment is in an assignment set' do
      let(:activity) { create(:activity) }
      let(:assignment) { create(:assignment, assignable: activity, section: section) }

      let(:assignment_set) do
        create(
          :assignment_set,
          section: section,
          due_date: assignment.due_date
        )
      end

      let(:section) { create(:section) }

      before do
        create(
          :assignment_set_activity,
          activity: activity,
          assignment_set: assignment_set,
          assignment_set_rank: 1
        )
      end

      it 'deletes the assignment set activity record associated to the assignment' do
        activity_assignment = described_class.new(activity, @owner, program, section_id: section.id)
        activity_assignment.unassign
        expect(
          AssignmentSetActivity.where(activity_id: activity.id).count
        ).to eq(0)
      end
    end
  end

  describe '#sections' do
    context 'when initialized with a section id' do
      subject(:activity_assignment) do
        described_class.new(@activity, @owner, program, params)
      end

      context 'when the section is not enterprise' do
        let(:params) { { section_id: @section.id } }

        it 'returns the section specified by that id' do
          expect(activity_assignment.sections).to eql [@section]
        end
      end

      context 'when the section is enterprise' do
        let(:params) { { section_id: enterprise_section.id } }
        let(:enterprise_course) { create(:enterprise_course) }
        let(:enterprise_section) { create(:enterprise_section, course: enterprise_course) }

        before do
          create_list(
            :section,
            2,
            course: enterprise_course,
            source_template_id: enterprise_section.id
          )
        end

        it 'returns the enterprise section specified by that id' do
          expect(activity_assignment.sections).to eql([enterprise_section])
        end
      end
    end

    context "when initialized with a course id," do
      it "should return all sections with that course id" do
        section_2 = create(:section, :course => @course, :instructor => @course.owner)
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)
        expect(activity_assignment.sections).to match_array([@section, section_2])
      end

      it "return all sections with that course id for the current_user" do
        co_instructor = create(:instructor)
        section_2 = create(:section, :course => @course)

        other_course = create(:course)
        other_course_section = create(:section, :course => other_course)

        create(:section_instructor, :section => section_2, :instructor => co_instructor)
        create(:section_instructor, :section => other_course_section, :instructor => co_instructor)

        activity_assignment = ActivityAssignment.new(@activity, co_instructor, program, :course_id => @course.id)
        expect(activity_assignment.sections).to eq([section_2])
      end
    end
  end

  describe "#course" do
    context "when initialized with a section id," do
      it "should return the course for the specified section" do
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
        expect(activity_assignment.course).to eql @section.course
      end
    end

    context "when initialized with a course id," do
      it "should return the course specified by the course id" do
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)
        expect(activity_assignment.course).to eql @course
      end
    end
  end

  describe "#due_date=" do
    it "should create an assignment record when there are none" do
      assignment = build_stubbed(:assignment)
      allow(Assignment).to receive(:activity_assignments).and_return([])
      expect(Assignment).to receive(:new).with(hash_including(:due_date => Date.today)).and_return(assignment)
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)
      activity_assignment.due_date = Date.today
    end

    it "should not change the due_date if assignments are present" do
      assignment = build_stubbed(:assignment, :due_date => 1.week.ago.to_date)
      allow(Assignment).to receive(:activity_assignments).and_return([assignment])
      expect(Assignment).not_to receive(:new)
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)
      activity_assignment.due_date = Date.today
      expect(activity_assignment.assignments.first.due_date).to eql 1.week.ago.to_date
    end
  end

  describe "#due_date" do
    context "when there are no assignments," do
      it "should return nil" do
        allow(Assignment).to receive(:activity_assignments).and_return([])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
        expect(activity_assignment.due_date).to be_nil
      end
    end

    context "when there is only one assignment," do
      it "should return the due date for that assignment" do
        assignment = build_stubbed(:assignment, :section => @section)
        allow(Assignment).to receive(:activity_assignments).and_return([assignment])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)

        expect(activity_assignment.due_date).to eql assignment.due_date
      end
    end

    context "when there are multiple assignments with the same due date," do
      it "should return the common due date" do
        assignment_1 = build_stubbed(:assignment, :section => @section)
        common_due_date = assignment_1.due_date

        section_2 = create(:section, :course => @course, :instructor => @course.owner)
        assignment_2 = build_stubbed(:assignment, :section => section_2, :due_date => common_due_date)
        allow(Assignment).to receive(:activity_assignments).and_return([assignment_1, assignment_2])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)

        expect(activity_assignment.due_date).to eql common_due_date
      end
    end

    context "when there are multiple assignments with different due dates," do
      it "should return nil" do
        assignment_1 = build_stubbed(:assignment, :section => @section)

        section_2 = create(:section, :course => @course, :instructor => @course.owner)

        assignment_2 = build_stubbed(:assignment, :section => section_2, :due_date => assignment_1.due_date + 1)
        allow(Assignment).to receive(:activity_assignments).and_return([assignment_1, assignment_2])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)

        expect(activity_assignment.due_date).to be_nil
      end
    end

    context "when there are multiple sections and activity is assigned in one but not another," do
      it "should return nil" do
        assignment_1 = build_stubbed(:assignment, :section => @section)
        section_2 = create(:section, :course => @course, :instructor => @course.owner)
        allow(Assignment).to receive(:activity_assignments).and_return([assignment_1])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)

        expect(activity_assignment.due_date).to be_nil
      end
    end
  end

  describe ".show_assessment" do
    context "when there are no assignments," do
      it "should return nil" do
        allow(Assignment).to receive(:activity_assignments).and_return([])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
        expect(activity_assignment.show_assessment).to be_nil
      end
    end

    context "when there is only one assignment," do
      it "should return the show_assessment value for that assignment" do
        assignment = build_stubbed(:assignment, :section => @section, :show_assessment => 'Show it now')
        allow(Assignment).to receive(:activity_assignments).and_return([assignment])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)

        expect(activity_assignment.show_assessment).to eql assignment.show_assessment
      end
    end

    context "when there are multiple assignments with the same show_assessment value," do
      it "should return the common show_assessment value" do
        assignment_1 = build_stubbed(:assignment, :section => @section, :show_assessment => 'Same release date')
        section_2 = create(:section, :course => @course, :instructor => @course.owner)
        assignment_2 = build_stubbed(:assignment, :section => section_2, :show_assessment => 'Same release date' )
        allow(Assignment).to receive(:activity_assignments).and_return([assignment_1, assignment_2])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)

        expect(activity_assignment.show_assessment).to eql 'Same release date'
      end
    end

    context "when there are multiple assignments with different show_assessment values," do
      it "should return nil" do
        assignment_1 = build_stubbed(:assignment, :section => @section, :show_assessment => 'Specific date')
        section_2 = create(:section, :course => @course, :instructor => @course.owner)
        assignment_2 = build_stubbed(:assignment, :section => section_2, :show_assessment => 'When I release')
        allow(Assignment).to receive(:activity_assignments).and_return([assignment_1, assignment_2])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)

        expect(activity_assignment.show_assessment).to be_nil
      end
    end

    context "when there are multiple sections and activity is assigned in one but not another," do
      it "should return nil" do
        assignment_1 = build_stubbed(:assignment, :section => @section, :show_assessment => 'When I release')
        section_2 = create(:section, :course => @course, :instructor => @course.owner)

        allow(Assignment).to receive(:activity_assignments).and_return([assignment_1])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)

        expect(activity_assignment.show_assessment).to be_nil
      end
    end
  end

  describe "#show_at" do
    context "when there are no assignments," do
      it "should return nil" do
        allow(Assignment).to receive(:activity_assignments).and_return([])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
        expect(activity_assignment.show_at).to be_nil
      end
    end

    context "when there is only one assignment," do
      it "should return the show_at date for that assignment" do
        show_at_date = 2.days.ago
        assignment = build_stubbed(:assignment, :section => @section, :show_at => show_at_date)
        allow(Assignment).to receive(:activity_assignments).and_return([assignment])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)

        expect(activity_assignment.show_at).to eql assignment.show_at
      end
    end

    context "when there are multiple assignments with the same assign_at date," do
      it "should return the common show_at date" do
        common_show_at_date = 3.days.ago
        assignment_1 = build_stubbed(:assignment, :section => @section, :show_at => common_show_at_date)

        section_2 = create(:section, :course => @course, :instructor => @course.owner)
        assignment_2 = build_stubbed(:assignment, :section => section_2, :show_at => common_show_at_date)
        allow(Assignment).to receive(:activity_assignments).and_return([assignment_1, assignment_2])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)

        expect(activity_assignment.show_at).to be_within(1).of(common_show_at_date)
      end
    end

    context "when there are multiple assignments with different show_at dates," do
      it "should return nil" do
        assignment_1 = build_stubbed(:assignment, :section => @section, :show_at => 2.days.ago)

        section_2 = create(:section, :course => @course, :instructor => @course.owner)
        assignment_2 = build_stubbed(:assignment, :section => section_2, :show_at => 3.days.ago)
        allow(Assignment).to receive(:activity_assignments).and_return([assignment_1, assignment_2])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)

        expect(activity_assignment.show_at).to be_nil
      end
    end

    context "when there are multiple sections and activity is assigned in one but not another," do
      it "should return nil" do
        assignment_1 = build_stubbed(:assignment, :section => @section, :show_at => 2.days.ago)
        section_2 = create(:section, :course => @course, :instructor => @course.owner)

        allow(Assignment).to receive(:activity_assignments).and_return([assignment_1])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)

        expect(activity_assignment.due_date).to be_nil
      end
    end
  end

  describe "#has_conflicting_due_dates?" do
    it "should be false when there are no assignments" do
      allow(Assignment).to receive(:activity_assignments).and_return([])
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
      expect(activity_assignment.has_conflicting_due_dates?).to be_falsey
    end

    it "should be false when there is only one assignment" do
      assignment = build_stubbed(:assignment, :section => @section)
      allow(Assignment).to receive(:activity_assignments).and_return([assignment])
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)

      expect(activity_assignment.has_conflicting_due_dates?).to be_falsey
    end

    it "should be false when there are multiple assignments with the same due date" do
      assignment_1 = build_stubbed(:assignment, :section => @section)
      common_due_date = assignment_1.due_date

      section_2 = create(:section, :course => @course, :instructor => @course.owner)
      assignment_2 = build_stubbed(:assignment, :section => section_2, :due_date => common_due_date)

      allow(Assignment).to receive(:activity_assignments).and_return([assignment_1, assignment_2])
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)

      expect(activity_assignment.has_conflicting_due_dates?).to be_falsey
    end

    it "should be true when there are multiple assignments with different due dates" do
      assignment_1 = build_stubbed(:assignment, :section => @section)

      section_2 = create(:section, :course => @course, :instructor => @course.owner)
      assignment_2 = build_stubbed(:assignment, :section => section_2, :due_date => assignment_1.due_date + 1)

      allow(Assignment).to receive(:activity_assignments).and_return([assignment_1, assignment_2])
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)

      expect(activity_assignment.has_conflicting_due_dates?).to be_truthy
    end

    it "should be true when there are multiple sections and activity is assigned in one but not another" do
      assignment_1 = build_stubbed(:assignment, :section => @section)
      section_2 = create(:section, :course => @course, :instructor => @course.owner)

      allow(Assignment).to receive(:activity_assignments).and_return([assignment_1])
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)

      expect(activity_assignment.has_conflicting_due_dates?).to be_truthy
    end
  end

  describe "#category_id=" do
    it "should create an assignment record when there are none" do
      assignment = build_stubbed(:assignment)
      allow(Assignment).to receive(:activity_assignments).and_return([])
      expect(Assignment).to receive(:new).with(hash_including(:category_id => 123)).and_return(assignment)
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)
      activity_assignment.category_id = 123
    end

    it "should not change the category_id if assignments are present" do
      assignment = build_stubbed(:assignment, :category_id => 999)
      allow(Assignment).to receive(:activity_assignments).and_return([assignment])
      expect(Assignment).not_to receive(:new)
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)
      activity_assignment.category_id = 123
      expect(activity_assignment.assignments.first.category_id).to eql 999
    end
  end

  describe "#category_id" do
    context "when there are no assignments," do
      it "should return nil" do
        allow(Assignment).to receive(:activity_assignments).and_return([])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
        expect(activity_assignment.category_id).to be_nil
      end
    end

    context "when there is only one assignment," do
      it "should return the category id for that assignment" do
        assignment = build_stubbed(:assignment, :section => @section)
        allow(Assignment).to receive(:activity_assignments).and_return([assignment])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
        expect(activity_assignment.category_id).to eql assignment.category_id
      end
    end

    context "when there are multiple assignments with the same category," do
      it "should return the common category id" do
        assignment_1 = build_stubbed(:assignment, :section => @section)
        common_category = assignment_1.category

        section_2 = create(:section, :course => @course, :instructor => @course.owner)
        assignment_2 = build_stubbed(:assignment, :section => section_2, :category => common_category)

        allow(Assignment).to receive(:activity_assignments).and_return([assignment_1, assignment_2])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)

        expect(activity_assignment.category_id).to eql common_category.id
      end
    end

    context "when there are multiple assignments with different categories," do
      it "should return nil" do
        assignment_1 = build_stubbed(:assignment, :section => @section)

        section_2 = create(:section, :course => @course, :instructor => @course.owner)
        category_2 = build_stubbed(:category)
        assignment_2 = build_stubbed(:assignment, :section => section_2, :category => category_2)

        allow(Assignment).to receive(:activity_assignments).and_return([assignment_1, assignment_2])
        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)

        expect(activity_assignment.category_id).to be_nil
      end
    end

    context "when there are multiple sections and activity is assigned in one but not another," do
      it "should return nil" do
        assignment_1 = build_stubbed(:assignment, :section => @section)
        section_2 = create(:section, :course => @course, :instructor => @course.owner)

        allow(Assignment).to receive(:activity_assignments).and_return([assignment_1])

        activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)
        expect(activity_assignment.category_id).to be_nil
      end
    end
  end

  describe "#has_conflicting_categories?" do
    it "should be false when there are no assignments" do
      allow(Assignment).to receive(:activity_assignments).and_return([])
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)

      expect(activity_assignment.has_conflicting_categories?).to be_falsey
    end

    it "should be false when there is only one assignment" do
      assignment = build_stubbed(:assignment, :section => @section)
      allow(Assignment).to receive(:activity_assignments).and_return([assignment])
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)

      expect(activity_assignment.has_conflicting_categories?).to be_falsey
    end

    it "should be false when there are multiple assignments with the same category" do
      assignment_1 = build_stubbed(:assignment, :section => @section)
      common_category = assignment_1.category

      section_2 = create(:section, :course => @course, :instructor => @course.owner)
      assignment_2 = build_stubbed(:assignment, :section => section_2, :category => common_category)

      allow(Assignment).to receive(:activity_assignments).and_return([assignment_1, assignment_2])
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)

      expect(activity_assignment.has_conflicting_categories?).to be_falsey
    end

    it "should be true when there are multiple assignments with different categories" do
      assignment_1 = build_stubbed(:assignment, :section => @section)

      section_2 = create(:section, :course => @course, :instructor => @course.owner)
      category_2 = build_stubbed(:category)
      assignment_2 = build_stubbed(:assignment, :section => section_2, :category => category_2)

      allow(Assignment).to receive(:activity_assignments).and_return([assignment_1, assignment_2])
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)

      expect(activity_assignment.has_conflicting_categories?).to be_truthy
    end

    it "should be true when there are multiple sections and activity is assigned in one but not another" do
      assignment_1 = build_stubbed(:assignment, :section => @section)
      section_2 = create(:section, :course => @course, :instructor => @course.owner)

      allow(Assignment).to receive(:activity_assignments).and_return([assignment_1])
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :course_id => @course.id)

      expect(activity_assignment.has_conflicting_categories?).to be_truthy
    end
  end

  describe "#has_conflicts?" do
    it "should return false if neither categories or due_dates have conflicts" do
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
      allow(activity_assignment).to receive(:has_conflicting_due_dates?).and_return(false)
      allow(activity_assignment).to receive(:has_conflicting_categories?).and_return(false)
      expect(activity_assignment.has_conflicts?).to be_falsey
    end

    it "should return true if categories have conflicts" do
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
      allow(activity_assignment).to receive(:has_conflicting_due_dates?).and_return(false)
      allow(activity_assignment).to receive(:has_conflicting_categories?).and_return(true)
      expect(activity_assignment.has_conflicts?).to be_truthy
    end

    it "should return true if due_dates have conflicts" do
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
      allow(activity_assignment).to receive(:has_conflicting_due_dates?).and_return(true)
      allow(activity_assignment).to receive(:has_conflicting_categories?).and_return(false)
      expect(activity_assignment.has_conflicts?).to be_truthy
    end
  end

  describe "#conflicts" do
    it "should return 'due date' if only due dates have conflicts" do
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
      allow(activity_assignment).to receive(:has_conflicting_due_dates?).and_return(true)
      allow(activity_assignment).to receive(:has_conflicting_categories?).and_return(false)
      expect(activity_assignment.conflicts).to eql ['Due date']
    end

    it "should return 'category' if only categories have conflicts" do
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
      allow(activity_assignment).to receive(:has_conflicting_due_dates?).and_return(false)
      allow(activity_assignment).to receive(:has_conflicting_categories?).and_return(true)
      expect(activity_assignment.conflicts).to eql ['Category']
    end

    it "should return 'due date' and 'category' if both due dates and categories have conflicts" do
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
      allow(activity_assignment).to receive(:has_conflicting_due_dates?).and_return(true)
      allow(activity_assignment).to receive(:has_conflicting_categories?).and_return(true)
      expect(activity_assignment.conflicts).to eql ['Due date', 'category']
    end

    it "should return empty array if neither due dates or categories have conflicts" do
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
      allow(activity_assignment).to receive(:has_conflicting_due_dates?).and_return(false)
      allow(activity_assignment).to receive(:has_conflicting_categories?).and_return(false)
      expect(activity_assignment.conflicts).to eql []
    end
  end

  describe "#min_date" do
    it "should return the start date of the specified course" do
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
      expect(activity_assignment.min_date).to eql @section.course.start_date
    end
  end

  describe "#max_date" do
    it "should return the end date of the specified course" do
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
      expect(activity_assignment.max_date).to eql @section.course.end_date
    end
  end

  describe "#categories" do
    it "should return a list of gradebook categories for the specified course" do
      category = create(:category, :course => @course)
      activity_assignment = ActivityAssignment.new(@activity, @owner, program, :section_id => @section.id)
      expect(activity_assignment.categories.to_a).to eql [category]
    end
  end

  describe '#valid?' do
    let(:activity_assignment) do
      ActivityAssignment.new(@activity, @owner, program, section_id: @section.id)
    end

    context 'when specified assignment attributes are not valid,' do
      it 'returns false' do
        expect(activity_assignment.valid?({})).to be_falsey
      end

      it 'assigns the assignment errors' do
        activity_assignment.valid?({})
        error_messages = activity_assignment.errors.full_messages
        expect(error_messages).to include 'Due date is required.'
        expect(error_messages).to include 'Please select a category.'
      end
    end

    context 'when specified assignment attributes are valid' do
      let(:category) { create(:category) }

      it 'returns true' do
        activity_assignment_attributes = { due_date: @course.start_date, category_id: category.id }
        expect(activity_assignment.valid?(activity_assignment_attributes)).to be_truthy
      end

      context 'when category_id refers to a invalid (non-existing) category' do
        let(:activity_assignment_attributes) do
          { due_date: @course.start_date, category_id: category.id + 1 }
        end

        it 'is invalid' do
          expect(activity_assignment.valid?(activity_assignment_attributes)).to be_falsey
        end

        it 'includes the correct error message' do
          activity_assignment.valid?(activity_assignment_attributes)
          expect(activity_assignment.errors.full_messages).to include 'Category is no longer valid.'
        end
      end
    end

  end

  describe "#assigned_sections" do
    it "returns all section in which the activity is assigned" do
      activity = create(:activity)

      section_1 = create(:section)
      section_2 = create(:section)
      section_3 = create(:section)

      assignment_1 = create(:assignment, assignable: activity, section: section_1)
      assignment_2 = create(:assignment, assignable: activity, section: section_2)

      activity_assignment = ActivityAssignment.new(
        activity,
        nil,
        program,
        section_id: section_1.id
      )

      expect(activity_assignment.assigned_sections).not_to include(section_3)
      expect(activity_assignment.assigned_sections).to include(section_2)
      expect(activity_assignment.assigned_sections).to include(section_1)
    end
  end

  describe "#all_sections" do
    it "returns all section in the course" do
      activity = create(:activity)

      course  = create(:course)
      section_1 = create(:section, :course => course)
      section_2 = create(:section, :course => course)
      section_3 = create(:section)

      activity_assignment = ActivityAssignment.new(
        activity,
        course.owner,
        program,
        section_id: section_1.id
      )

      expect(activity_assignment.all_sections).not_to include(section_3)
      expect(activity_assignment.all_sections).to include(section_2)
      expect(activity_assignment.all_sections).to include(section_1)
    end
  end
end

describe ActivityAssignment::AssignmentParamsUpdater do
  let(:lesson) { create(:lesson_with_unit) }
  let(:program) { lesson.program }
  let(:concept) { create(:concept, lesson: lesson, program: program) }
  let(:section) { create(:section) }
  let(:activity) { create(:activity, lesson: lesson, concept: concept) }

  def expected_time(s)
    Time.use_zone("Pacific Time (US & Canada)") do
      Time.zone.parse(s)
    end
  end

  describe "#adjust_time_zone" do
    it "time based params are adjusted to section time zone" do
      params = { :show_at => 1.day.ago.to_s ,
                 :grades_available_at =>  2.day.ago.to_s ,
                 :answers_available_at =>  3.day.ago.to_s  }
      allow(section).to receive(:time_zone).and_return("Pacific Time (US & Canada)")
      params_updater = ActivityAssignment::AssignmentParamsUpdater.new(activity, section, nil, program, params)
      params_updater.adjust_time_zone
      expect(params_updater.updated_params[:show_at].zone).to eql(expected_time(params[:show_at]).zone)
      expect(params_updater.updated_params[:grades_available_at].zone).to eql(expected_time(params[:grades_available_at]).zone)
      expect(params_updater.updated_params[:answers_available_at].zone).to eql(expected_time(params[:answers_available_at]).zone)
    end
  end

  describe "#set_new_assignment_params" do
    it "assigns the assignable and section_id" do
      params_updater = ActivityAssignment::AssignmentParamsUpdater.new(activity, section, nil, program, {})
      params_updater.set_new_assignment_params
      expect(params_updater.updated_params[:assignable]).to eql(activity)
      expect(params_updater.updated_params[:section_id]).to eql(section.id)
    end
  end

  describe "#set_next_rank" do
    it "assigns the next rank" do
      expect(Assignment).to receive(:next_rank).with(section, 'due_date', activity).and_return(10101)
      params_updater = ActivityAssignment::AssignmentParamsUpdater.new(activity, section, 'assignment', program,  {:due_date => 'due_date'})
      params_updater.set_next_rank
    end
  end
end
