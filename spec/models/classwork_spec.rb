describe Classwork do
  def new_classwork_with_units
    @program = create(:program)
    @first_unit = create(:unit, program: @program, name: "Unit 1", rank: 1)
    @last_unit =  create(:unit, program: @program, name: "Unit 2", rank: 2)
    @course = create(:course, program: @program, first_unit: @first_unit, last_unit: @last_unit)
    @section = create(:section, course: @course)
    new_classwork(@section)
  end

  def new_classwork(section = nil)
    @user = create(:student)
    if section
      @section = section
    else
      @section = create(:section, :course => create(:course) )
    end
    @classwork = described_class.new(@user, @section)
  end

  def new_classwork_without_section
    @user = create(:student)
    @classwork = described_class.new(@user)
  end

  def new_classwork_by_id
    @user = create(:student)
    @section = create(:section, :course => create(:course) )
    @classwork = described_class.new(@user, @section.id)
  end

  context "when initialized by passing a section," do
    it "should assign the section to an attribute" do
      new_classwork
      expect(@classwork.section).to eql @section
    end

    it "should assign the section_id to an attribute" do
      new_classwork
      expect(@classwork.section_id).to eql @section.id
    end
  end

  context "when initialized by passing a section id," do
    it "should assign the section to an attribute" do
      new_classwork_by_id
      expect(@classwork.section).to eql @section
    end

    it "should assign the section_id to an attribute" do
      new_classwork_by_id
      expect(@classwork.section_id).to eql @section.id
    end
  end

  context "when initialized without a section id," do
    it "should assign 0 to the section_id attribute" do
      new_classwork_without_section
      expect(@classwork.section_id).to eql 0
    end
  end


  describe "#user_id" do
    it "returns user id" do
      new_classwork
      expect(@classwork.user_id).to eql(@user.id)
    end
  end

  describe "#closed_section?" do
    it "returns false if current section is active for this user" do
      new_classwork
      @user.sections << @section
      expect(@classwork.closed_section?).to be_falsey
    end

    it "returns true if section is closed" do
      new_classwork
      @section.course.start_date = 12.months.ago
      @section.course.end_date = 6.months.ago
      @section.course.allow_past_end_date = true
      @section.course.updated_by = @section.course.owner_id
      @section.course.save!
      @user.sections << @section
      expect(@classwork.closed_section?).to be_truthy
    end
  end

  describe "#units_covered" do
    before(:each) do
      new_classwork_with_units
    end

    it "looks up units from study schedule" do
      expect(@course).to receive(:units_covered)
      @classwork.units_covered
    end

    it "saves the result of the units_covered and doesn't repeat it" do
      expect(@course).to receive(:units_covered).once.and_return('valid_units')
      allow(@course).to receive(:units_covered).and_return('valid_units')
      @classwork.units_covered
      @classwork.units_covered
    end
  end

  describe "#completed_count" do
    before(:each) do
      new_classwork_with_units
      @lesson_1 = create(:lesson)
      @lesson_2 = create(:lesson)
      allow(@section.course).to receive(:units_covered).and_return([@lesson_1, @lesson_2])

      assigned_activities = Array.new(3){|index| create(:activity, :lesson => @lesson_1)}
      assigned_activities.each do |activity|
        due_date = (@section.course.start_date + 1)
        create(:assignment, :section => @section, :assignable => activity, :due_date => due_date)
      end

      assigned_activities.each do |activity|
        create(:attempt, :activity => activity, :user => @user, :section => @section, :status_code => 2)
      end
    end

    it "raises an error if an unsupported activity type is requested" do
      expect{@classwork.completed_count(:fake_activity_type, @lesson_1.id) }.to raise_error(/activity type/)
    end

    it "returns the correct number of completed assigned activities" do
      expect(@classwork.completed_count(:assigned, @lesson_1.id)).to eql(3)
      expect(@classwork.completed_count(:assigned, @lesson_2.id)).to eql(0)
    end

    it "saves the result of the new first call and doesn't repopulate it" do
      expect(Attempt).to receive(:all_submitted_and_completed_activities).once.and_return(@attempted_activities)
      @classwork.completed_count(:assigned, @lesson_2.id)
    end
  end

  describe '#all_assignments_for_date' do
    let(:section) { create(:section) }
    let(:user) { create(:user) }
    let(:due_date) { 5.days.from_now.to_date }

    let(:classwork) { described_class.new(user, section) }

    it 'sorts assignments by their rank' do
      assignment_1 = create(
        :assignment,
        due_date: due_date,
        rank: 2,
        section: section
      )
      assignment_2 = create(
        :assignment,
        due_date: due_date,
        rank: 1,
        section: section
      )

      expect(
        classwork.all_assignments_for_date(due_date)
      ).to eq([assignment_2, assignment_1])
    end

    context 'when no concept or category are passed,' do
      it 'returns assignments only for the current section and specified ' \
         'due date' do
        assignment = create(:assignment, due_date: due_date, section: section)

        create(:assignment, due_date: due_date, section: create(:section))

        create(:assignment, due_date: due_date + 1, section: section)

        expect(
          classwork.all_assignments_for_date(due_date)
        ).to contain_exactly(assignment)
      end
    end

    it 'returns only assignments for a given concept if one is specified' do
      concept_1 = create(:concept)
      concept_2 = create(:concept)

      activity_1 = create(:activity, concept: concept_1)
      activity_2 = create(:activity, concept: concept_2)

      assignment = create(
        :assignment,
        assignable: activity_1,
        due_date: due_date,
        section: section
      )

      create(
        :assignment,
        assignable: activity_2,
        due_date: due_date,
        section: section
      )
      expect(
        classwork.all_assignments_for_date(due_date, concept_1)
      ).to contain_exactly(assignment)
    end

    it 'returns only assignments for a given category if one is specified' do
      category_1 = create(:category)
      category_2 = create(:category)

      assignment = create(
        :assignment,
        category: category_1,
        due_date: due_date,
        section: section
      )

      create(
        :assignment,
        category: category_2,
        due_date: due_date,
        section: section
      )
      expect(
        classwork.all_assignments_for_date(due_date, nil, category_1)
      ).to contain_exactly(assignment)
    end

    it 'loads the assignments ordered by assignment rank when there is a custom order' do
      assignment_one = create(:assignment, due_date: due_date, section_id: section.id, rank: 2)
      assignment_two = create(:assignment, due_date: due_date, section_id: section.id, rank: 1)
      expect(
        classwork.all_assignments_for_date(due_date)
      ).to eq([assignment_two, assignment_one])
    end

    it 'loads the assignments ordered by unit rank when assignment rank tie' do
      unit_one = create(:unit, rank: 1)
      unit_two = create(:unit, rank: 2)
      lesson_one = create(:lesson, unit: unit_one)
      lesson_two = create(:lesson, unit: unit_two)
      activity_one = create(:activity, lesson: lesson_two)
      activity_two = create(:activity, lesson: lesson_one)
      assignment_one = create(
        :assignment,
        assignable: activity_one,
        section_id: section.id,
        due_date: due_date,
        rank: 1
      )
      assignment_two = create(
        :assignment,
        assignable: activity_two,
        section_id: section.id,
        due_date: due_date,
        rank: 1
      )
      expect(
        classwork.all_assignments_for_date(due_date)
      ).to eq([assignment_two, assignment_one])
    end

    it 'loads the assignments ordered by lesson rank when assignment rank and unit rank tie' do
      unit_one = create(:unit, rank: 1)
      lesson_one = create(:lesson, unit: unit_one, rank: 3)
      lesson_two = create(:lesson, unit: unit_one, rank: 4)
      activity_one = create(:activity, lesson: lesson_two)
      activity_two = create(:activity, lesson: lesson_one)
      assignment_one = create(
        :assignment,
        assignable: activity_one,
        section_id: section.id,
        due_date: due_date,
        rank: 1
      )
      assignment_two = create(
        :assignment,
        assignable: activity_two,
        section_id: section.id,
        due_date: due_date,
        rank: 1
      )
      expect(
        classwork.all_assignments_for_date(due_date)
      ).to eq([assignment_two, assignment_one])
    end

    it 'loads the assignments ordered by concept rank when assignment rank, unit rank ' \
       'and lesson rank tie' do
      unit_one = create(:unit, rank: 1)
      lesson_one = create(:lesson, unit: unit_one, rank: 1)
      concept_one = create(:concept, lesson: lesson_one, rank: 2)
      concept_two = create(:concept, lesson: lesson_one, rank: 3)
      activity_one = create(:activity, lesson: lesson_one, concept: concept_two)
      activity_two = create(:activity, lesson: lesson_one, concept: concept_one)
      assignment_one = create(
        :assignment,
        assignable: activity_one,
        section_id: section.id,
        due_date: due_date,
        rank: 1
      )
      assignment_two = create(
        :assignment,
        assignable: activity_two,
        section_id: section.id,
        due_date: due_date,
        rank: 1
      )
      expect(
        classwork.all_assignments_for_date(due_date)
      ).to eq([assignment_two, assignment_one])
    end

    it 'loads the assignments ordered by activity concept_rank when assignment rank, unit rank, ' \
       'lesson rank and concept rank tie' do
      unit_one = create(:unit, rank: 1)
      lesson_one = create(:lesson, unit: unit_one, rank: 1)
      concept_one = create(:concept, lesson: lesson_one, rank: 1)
      activity_one = create(:activity, lesson: lesson_one, concept: concept_one, concept_rank: 3)
      activity_two = create(:activity, lesson: lesson_one, concept: concept_one, concept_rank: 2)
      assignment_one = create(
        :assignment,
        assignable: activity_one,
        section_id: section.id,
        due_date: due_date,
        rank: 1
      )
      assignment_two = create(
        :assignment,
        assignable: activity_two,
        section_id: section.id,
        due_date: due_date,
        rank: 1
      )
      expect(
        classwork.all_assignments_for_date(due_date)
      ).to eq([assignment_two, assignment_one])
    end

    it 'loads the assignments ordered by activity toc_location_rank when assignment rank, ' \
       'unit rank, lesson rank, concept rank and activity concept_rank tie' do
      unit_one = create(:unit, rank: 1)
      lesson_one = create(:lesson, unit: unit_one, rank: 1)
      concept_one = create(:concept, lesson: lesson_one, rank: 1)
      activity_one = create(
        :activity,
        lesson: lesson_one,
        concept: concept_one,
        concept_rank: 1,
        toc_location_rank: 3
      )
      activity_two = create(
        :activity,
        lesson: lesson_one,
        concept: concept_one,
        concept_rank: 1,
        toc_location_rank: 2
      )
      assignment_one = create(
        :assignment,
        assignable: activity_one,
        section_id: section.id,
        due_date: due_date,
        rank: 1
      )
      assignment_two = create(
        :assignment,
        assignable: activity_two,
        section_id: section.id,
        due_date: due_date,
        rank: 1
      )
      expect(
        classwork.all_assignments_for_date(due_date)
      ).to eq([assignment_two, assignment_one])
    end

    context 'when some activities are assigned individually,' do
      it 'includes only the activities assigned to all students or the ' \
         'current student' do
        # assigned to all students
        assignment_1 = create(
          :assignment,
          due_date: due_date,
          individually_assignable: false,
          section: section
        )

        # individually assigned to current student
        assignment_2 = create(
          :assignment,
          due_date: due_date,
          individually_assignable: true,
          section: section
        )

        IndividualAssignment.create!(
          activity_id: assignment_2.assignable_id,
          section_id: section.id,
          user_id: user.id
        )

        # individually assigned, but not to current student
        create(
          :assignment,
          due_date: due_date,
          individually_assignable: true,
          section: section
        )

        expect(
          classwork.all_assignments_for_date(due_date)
        ).to contain_exactly(assignment_1, assignment_2)
      end
    end

    context 'when some activities are assigned with individual due dates,' do
      let(:other_due_date) { due_date + 1 }

      it 'includes only the activities assigned to all students or the ' \
         'current student with no individual due date, or the current ' \
         'student with an individual due date matching the specified date' do
        # assigned to all students
        all_students_assignment = create(
          :assignment,
          due_date: due_date,
          individually_assignable: false,
          section: section
        )

        # individually assigned to current student, no individual due date
        individual_assignment_no_due_date = create(
          :assignment,
          due_date: due_date,
          individually_assignable: true,
          section: section
        )

        IndividualAssignment.create!(
          activity_id: individual_assignment_no_due_date.assignable_id,
          section_id: section.id,
          user_id: user.id
        )

        # individually assigned to current student, individual due date
        # matching specified date
        individual_assignment_matching_due_date = create(
          :assignment,
          due_date: other_due_date,
          individually_assignable: true,
          section_id: section.id
        )

        IndividualAssignment.create!(
          activity_id: individual_assignment_matching_due_date.assignable_id,
          due_date: due_date,
          section_id: section.id,
          user_id: user.id
        )

        # individually assigned to current student, individual due date
        # different from specified date
        individual_assignment_non_matching_due_date = create(
          :assignment,
          due_date: due_date,
          individually_assignable: true,
          section_id: section.id
        )

        IndividualAssignment.create!(
          activity_id: individual_assignment_non_matching_due_date.assignable_id,
          due_date: other_due_date,
          section_id: section.id,
          user_id: user.id
        )

        # individually assigned, but not to current student
        other_student_assignment = create(
          :assignment,
          due_date: other_due_date,
          individually_assignable: true,
          section_id: section.id
        )

        IndividualAssignment.create!(
          activity_id: other_student_assignment.assignable_id,
          due_date: due_date,
          section_id: section.id,
          user_id: create(:student).id
        )

        expect(
          classwork.all_assignments_for_date(due_date)
        ).to contain_exactly(
          all_students_assignment,
          individual_assignment_no_due_date,
          individual_assignment_matching_due_date
        )
      end
    end
  end

  describe "#select_completed_activities" do
    it "calls completed_activity_ids from Assignments" do
      new_classwork
      expect(Attempt).to receive(:completed_activity_ids).with(@user, @section, 'valid_activities')
      @classwork.select_completed_activities('valid_activities')
    end
  end

  describe "#select_assigned_activities" do
    before(:each) do
      new_classwork_with_units
      @activity = create(:activity)
    end

    it "should include assigned activities" do
      assignment = create(:assignment, :due_date => Date.today - 1, :section => @section,
                                                        :assignable => @activity)

      assigned_activities = @classwork.select_assigned_activities([@activity])
      expect(assigned_activities).to include(@activity)
    end

    it "should not include unassigned activities" do
      assigned_activities = @classwork.select_assigned_activities([@activity])
      expect(assigned_activities).not_to include(@activity)
    end
  end

  describe "#new_workset" do
    before(:each) do
      new_classwork
    end

    it "with a valid section, calls Workset.create_or_update" do
      activity_ids = [1, 2]
      expect(Workset).to receive(:create_or_update).with(@user, @section, activity_ids.join(','))
      @classwork.new_workset(activity_ids)
    end

    it "without a valid section, doesn't call Workset.create_or_update" do
      @classwork = described_class.new(@user, nil)
      expect(Workset).not_to receive(:create_or_update)
      expect(@classwork.new_workset([1, 2])).to be_nil
    end
  end

  describe "#current_workset" do
    it "does not call Workset.current when no activity is specified" do
      new_classwork
      expect(Workset).not_to receive(:current)
      @classwork.current_workset
    end

    it "calls Workset.current with an activity if one is specified" do
      new_classwork
      activity = build_stubbed(:activity)
      allow(@classwork).to receive(:assignment).with(activity).and_return(double(Assignment))
      expect(Workset).to receive(:current).with(@user, @section, activity)
      @classwork.current_workset(activity)
    end
  end

  describe "#find_or_new_attempt" do
    let(:activity) { create(:activity) }
    context "when a section exists," do
      before(:each) do
        new_classwork
      end

      it "calls Attempt.find_or_new" do
        attempt = create(:attempt)
        expect(Attempt).to receive(:find_or_new).with(@user, activity, @section.id).and_return(attempt)
        @classwork.find_or_new_attempt(activity)
      end

      it "calls Attempt.find" do
        attempt = create(:attempt)
        expect(Attempt).to receive(:find_or_new).with(@user, activity, @section.id).and_return(attempt)
        @classwork.find_or_new_attempt(activity)
      end

      it "searches using activity_id if one is passed instead of an activity" do
        attempt = create(:attempt)
        expect(Attempt).to receive(:find_or_new).with(@user, activity, @section.id).and_return(attempt)
        @classwork.find_or_new_attempt(activity)
      end

      it "assigns a scoring_ruleset object if not already set." do
        attempt = build_stubbed(:attempt, scoring_ruleset: nil)
        expect(attempt).to receive(:scoring_ruleset=)
        allow(Attempt).to receive(:find_or_new).and_return(attempt)
        @classwork.find_or_new_attempt(activity)
      end
    end

    context "when no section exists," do
      it "should call Attempt.find_or_new with a section_id of 0" do
        new_classwork_without_section
        attempt = create(:attempt)
        expect(Attempt).to receive(:find_or_new).with(@user, activity, 0).and_return(attempt)
        @classwork.find_or_new_attempt(activity)
      end
    end
  end

  describe '#ensure_completed_attempt' do
    before do
      new_classwork
      @activity = create(:activity)
    end

    it 'calls Attempt.create_completed' do
      expect(Attempt).to receive(:create_completed).with(@user, @activity, @section)
      @classwork.ensure_completed_attempt(@activity)
    end

    it 'does not call Attempt.create_completed if already completed' do
      Attempt.create_completed(@user, @activity, @section.id)
      expect(Attempt).not_to receive(:create_completed).with(@user, @activity, @section)
      @classwork.ensure_completed_attempt(@activity)
    end
  end

  describe '#incomplete?' do
    before do
      user = build_stubbed(:student)
      @activity = build_stubbed(:activity)
      @incomplete = build_stubbed(:activity)
      @section = build_stubbed(:section)
      @classwork = described_class.new(user, @section)
      @due_date = Date.today
      @assignment = build_stubbed(
        :assignment,
        due_date: @due_date,
        assignable: @activity,
        section: @section
      )
      allow(Attempt).to receive(:completed_activity_ids).with(user, @section.id, [@activity]).and_return([@activity.id])
      allow(Attempt).to receive(:completed_activity_ids).with(user, @section.id, [@incomplete]).and_return([])
    end

    context "returns activity incomplete status" do
      it "should be true when not complete" do
        expect(@classwork).to receive(:select_completed_activities).with([@incomplete]).and_return([@incomplete.id])
        expect(@classwork.incomplete?(@incomplete)).to be_falsey
      end

      it "should be false when complete" do
        expect(@classwork).to receive(:select_completed_activities).with([@activity]).and_return([])
        expect(@classwork.incomplete?(@activity)).to be_truthy
      end
    end
  end

  describe '#overdue?' do
    # rubocop:disable RSpec/PredicateMatcher
    # Because expect(classwork).to be_overdue(activity) doesn't make sense.
    let(:activity) { create(:activity) }
    let(:section) { create(:section) }
    let(:student) { build_stubbed(:student) }

    it 'is false without a section' do
      classwork = described_class.new(student)
      expect(classwork.overdue?(activity)).to be_falsey
    end

    context 'with a section,' do
      it 'is false if the activity is not assigned' do
        classwork = described_class.new(student, section)
        expect(classwork.overdue?(activity)).to be_falsey
      end

      context 'with an assignment,' do
        let(:future_assignment) do
          create(
            :assignment,
            assignable: activity,
            due_date: 5.days.from_now,
            section: section
          )
        end

        let(:past_due_assignment) do
          create(
            :assignment,
            assignable: activity,
            due_date: 2.days.ago,
            section: section
          )
        end

        it 'is false if the assignment is due in the future' do
          future_assignment
          classwork = described_class.new(student, section)
          expect(classwork.overdue?(activity)).to be_falsey
        end

        context 'when the assignment due date has passed,' do
          before do
            past_due_assignment
          end

          it 'is true if the activity has not been completed' do
            allow(Attempt).to receive(:completed_activity_ids).and_return([])

            classwork = described_class.new(student, section)

            expect(classwork.overdue?(activity)).to be_truthy
          end

          it 'is false if the activity has been completed' do
            allow(Attempt).to receive(:completed_activity_ids).and_return([activity.id])

            classwork = described_class.new(student, section)

            expect(classwork.overdue?(activity)).to be_falsey
          end
        end

        context 'with a custom due date,' do
          let(:student) { create(:student) }

          it 'is false if the custom due date is in the future' do
            past_due_assignment
            create(:individual_assignment,
                   activity_id: activity.id,
                   due_date: 5.days.from_now,
                   section_id: section.id,
                   user_id: student.id)

            classwork = described_class.new(student, section)

            expect(classwork.overdue?(activity)).to be_falsey
          end

          context 'when the assignment due date has passed,' do
            before do
              future_assignment
              create(:individual_assignment,
                     activity_id: activity.id,
                     due_date: 2.days.ago,
                     section_id: section.id,
                     user_id: student.id)
            end

            it 'is true if the activity has not been completed' do
              allow(Attempt).to receive(:completed_activity_ids).and_return([])

              classwork = described_class.new(student, section)

              expect(classwork.overdue?(activity)).to be_truthy
            end

            it 'is false if the activity has been completed' do
              allow(Attempt).to receive(:completed_activity_ids).and_return([activity.id])

              classwork = described_class.new(student, section)

              expect(classwork.overdue?(activity)).to be_falsey
            end
          end
        end
      end
    end
    # rubocop:enable RSpec/PredicateMatcher
  end

  describe "#assignment" do
    before(:each) do
      @section = build_stubbed(:section)
      @classwork = described_class.new(build_stubbed(:student), @section)
    end

    it "should return the assignment if passed an activity assigned for the current section" do
      activity = create(:activity)
      assignment = create(:assignment, :assignable => activity, :section => @section)
      expect(@classwork.assignment(activity)).to eql assignment
    end

    it "should return nil if the activity is not assigned for the current section" do
      activity = create(:activity)
      expect(@classwork.assignment(activity)).to be_nil
    end


    it "should return nil if not currently in a section" do
      activity = create(:activity)
      classwork = described_class.new(build_stubbed(:student))
      expect(classwork.assignment(activity)).to be_nil
    end
  end

  describe "#current_scoring_ruleset" do
    context "for unassigned activities" do
      it "should return the default scoring_ruleset" do
        classwork = new_classwork_with_units
        activity = create(:activity)

        assignment = nil
        received = classwork.current_scoring_ruleset(assignment)

        expect(received).to eql ScoringRuleset.default
      end
    end

    context "for assigned activities" do
      it "should return the scoring ruleset for the assignment's gradebook category" do
        classwork = new_classwork_with_units
        activity = create(:activity)

        scoring_ruleset = create(:scoring_ruleset)
        category = create(:category, :course => @course, :current_scoring_ruleset_id => scoring_ruleset.id)
        category.save!

        assignment = create(:assignment,
                                    :due_date => @course.end_date - 1,
                                    :assignable => activity,
                                    :category => category,
                                    :section => @section)


        received = classwork.current_scoring_ruleset(assignment)
        expect(received).to eql scoring_ruleset
      end

      it "should return true if enhanced_feedback_disable is set in true" do
        classwork = new_classwork_with_units
        activity = create(:activity)

        scoring_ruleset = create(:scoring_ruleset)
        category = create(:category, :course => @course, :current_scoring_ruleset_id => scoring_ruleset.id, :enhanced_feedback_disabled => true)
        category.save!

        assignment = create(:assignment,
                                    :due_date => @course.end_date - 1,
                                    :assignable => activity,
                                    :category => category,
                                    :section => @section)

        enhanced_feedback_disable = classwork.disable_enhanced_feedback?(assignment)
        expect(enhanced_feedback_disable).to be_truthy
      end

      it "should return false if enhanced_feedback_disable is set in false" do
        classwork = new_classwork_with_units
        activity = create(:activity)

        scoring_ruleset = create(:scoring_ruleset)
        category = create(:category, :course => @course, :current_scoring_ruleset_id => scoring_ruleset.id)
        category.save!

        assignment = create(:assignment,
                                :due_date => @course.end_date - 1,
                                :assignable => activity,
                                :category => category,
                                :section => @section)

        enhanced_feedback_disable = classwork.disable_enhanced_feedback?(assignment)
        expect(enhanced_feedback_disable).to be_falsey
      end
    end
  end

  describe "#disable_enhanced_feedback?" do
    let(:section)   { build_stubbed(:section)}
    let(:classwork) { new_classwork(section) }

    context "when assignment is nil" do
      it "returns false" do
        expect(classwork.disable_enhanced_feedback?(nil)).to be_falsey
      end
    end

    context "when assignment exists" do
      let(:assignment) { build_stubbed(:assignment) }

      context 'when assignment is set to disable enhanced feedback' do
        it 'returns true' do
          allow(assignment).to receive(:disable_enhanced_feedback?).and_return(true)
          expect(classwork.disable_enhanced_feedback?(assignment)).to be_truthy
        end
      end

      context 'when assignment is set to enable enhanced feedback' do
        it 'returns true' do
          allow(assignment).to receive(:disable_enhanced_feedback?).and_return(false)
          expect(classwork.disable_enhanced_feedback?(assignment)).to be_falsey
        end
      end
    end
  end
end
