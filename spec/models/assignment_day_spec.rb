describe AssignmentDay, :core => true do
  context "#<<" do
    before(:each) do
      @concept = create(:concept)
      activities = [].fill(0..1) { |n| create(:activity, :concept => @concept) }
      assignments = [create(:assignment, :assignable => activities[0], :rank => 1),
                     create(:assignment, :assignable => activities[1], :rank => 2)]
      @assignment_day = AssignmentDay.new(:due_date => Date.today)
      assignments.each do |assignment|
        @assignment_day << assignment
      end
    end

    it "should add assignments in order received" do
      expect(@assignment_day.assignments[0].rank).to eql(1)
      expect(@assignment_day.assignments[1].rank).to eql(2)
    end
  end

  describe "#banks" do
    it "returns a bank for each group of activities and assessments" do
      concept1 = create(:concept, :name => 'concept1', :assessment => false)
      concept2 = create(:concept, :name => 'concept2', :assessment => false)
      assessment_concept = create(:concept, :name => 'assessment_concept', :assessment => true)
      assessment_strand  = create(:toc_entry)
      lesson = create(:lesson)
      lesson.toc_entries = [assessment_strand]

      group1 = [].fill(0..1) { |n| create(:activity, :concept => concept1,
                                                      :minutes_to_complete => 8, :lesson => lesson ) }
      group2 = [].fill(0..2) { |n| create(:activity, :concept => concept2,
                                                      :minutes_to_complete => 9, :lesson => lesson ) }
      group3 = [].fill(0..3) { |n| create(:activity, :concept => concept1,
                                                      :minutes_to_complete => 8, :lesson => lesson ) }
      group4 = [create(:activity, :concept => assessment_concept, :minutes_to_complete => 8, :lesson => lesson,
                                   :toc_location => assessment_strand.location)]


      @assignment_day = AssignmentDay.new(:due_date => Date.today)
      @assignment_day.lesson_plan_groups = [group1, group2, group3, group4]

      # expected results
      bank_vals = Array.new
      bank_vals << { 'concept' => concept1, 'assigned_count' => 2, 'assigned_minutes' => 20 }
      bank_vals << { 'concept' => concept2, 'assigned_count' => 3, 'assigned_minutes' => 30 }
      bank_vals << { 'concept' => concept1, 'assigned_count' => 4, 'assigned_minutes' => 35 }
      bank_vals << { 'concept' => assessment_concept, 'assigned_count' => 1, 'assigned_minutes' => 10 }

      @assignment_day.banks.each_with_index do |bank, index|
        expect(bank.class).to eql Bank
        expect(bank.concept).to eql(bank_vals[index]['concept'])
        expect(bank.assigned_count).to eql(bank_vals[index]['assigned_count'])
        expect(bank.assigned_minutes).to eql(bank_vals[index]['assigned_minutes'])
      end

      expect(@assignment_day.total_minutes_for_activities).to eql(20 + 30 + 35)
      expect(@assignment_day.total_minutes_for_assessments).to eql 10
      expect(@assignment_day.total_activities).to eql(2 + 3 + 4)
      expect(@assignment_day.total_assessments).to eql 1

    end
  end

  describe "#assign_from_lesson_plan_groups" do
    context "with groups that contain activities," do
      it "creates assignments for each activity" do
        due_date = Date.today
        assignment_day = AssignmentDay.new(:due_date => due_date)

        section = create(:section)

        activity = build_stubbed(:activity)
        lesson_plan_group = [activity]

        assignment = double(Assignment, :assignable => activity)
        assignment_day.lesson_plan_groups = [lesson_plan_group]
        category = build_stubbed(:category)

        expect(Assignment).to receive(:create!).with(:section => section,
                                                 :category_id => category.id,
                                                 :assignable => activity,
                                                 :due_date => due_date,
                                                 :rank => 1).and_return(assignment)
        assignment_day.assign_from_lesson_plan_groups(section, category.id)
      end
    end
  end

  describe "#concepts" do
    it "returns concepts, preserving assignment order" do
      concept1 = create(:concept, :name => 'concept1')
      concept2 = create(:concept, :name => 'concept2')
      concept3 = create(:concept, :name => 'concept3')

      bank1 = double(Bank, :concept => concept1)
      bank2 = double(Bank, :concept => concept2)
      bank3 = double(Bank, :concept => concept3)

      @assignment_day = AssignmentDay.new
      allow(@assignment_day).to receive(:banks).and_return([bank1, bank2, bank3])
      expect(@assignment_day.concepts).to eql([concept1, concept2, concept3])

      allow(@assignment_day).to receive(:banks).and_return([bank3, bank1, bank2])
      expect(@assignment_day.concepts).to eql([concept3, concept1, concept2])
    end
  end

  describe "#activities" do

    before (:each) do
      @assignment_day = AssignmentDay.new
    end

    context "when there are lesson plan groups," do
      it "flattens the lesson plan groups and returns activities" do
        concept1 = create(:concept, :name => 'concept1')
        concept2 = create(:concept, :name => 'concept2')

        group1 = [].fill(0..1) { |n| create(:activity, :concept => concept1,
                                                        :minutes_to_complete => 8) }
        group2 = [].fill(0..2) { |n| create(:activity, :concept => concept2,
                                                        :minutes_to_complete => 9) }

        @assignment_day.lesson_plan_groups = [group1,group2]

        activities = @assignment_day.activities

        expect(activities.first).to eql(group1.first)
        expect(activities.last).to eql(group2.last)
        expect(activities.count).to eql(group1.count + group2.count)
      end
    end

    context "when there are no lesson plan groups," do
      it "loops through the assignments, returning the assignment activities in order" do
        @assignment_day.lesson_plan_groups = []

        @assignment_day.assignments << create(:assignment, :assignable => create(:activity, :title => 'act1'), :rank => 1)
        @assignment_day.assignments << create(:assignment, :assignable => create(:activity, :title => 'act2'), :rank => 2)

        results = @assignment_day.activities

        expect(results.first.title).to eql('act1')
        expect(results.last.title).to  eql('act2')
      end
    end
  end

  describe "#activities_and_assessment_count_label" do
    let(:assessment_1) { double('assessment', :strand_singular_label => 'assessment_type') }
    let(:assessment_2) { double('assessment', :strand_singular_label => 'another_type') }
    let(:bank_1) { double(Bank, :assessment => assessment_1) }
    let(:bank_2) { double(Bank, :assessment => assessment_2) }
    let(:assignment_day) { AssignmentDay.new }

    context "when there is only one activity" do
      before do
        allow(assignment_day).to receive(:total_activities).and_return(1)
        allow(assignment_day).to receive(:banks).and_return([bank_1])
      end

      it "contains activity count in singular" do
        expect(assignment_day.activities_and_assessment_count_label).to include '1 activity'
      end

      it "contains activity concept and count in singular" do
        expect(assignment_day.activities_and_assessment_count_label).to include '1 assessment_type'
      end
    end

    context "when there is more than one activity" do
      before do
        allow(assignment_day).to receive(:total_activities).and_return(4)
        allow(assignment_day).to receive(:banks).and_return([bank_1, bank_1, bank_1, bank_2])
      end

      it "contains activity count pluralized" do
        expect(assignment_day.activities_and_assessment_count_label).to include '4 activities'
      end

      it "contains every activity concept and a counter for each one" do
        expect(assignment_day.activities_and_assessment_count_label).to include '3 assessment_types'
        expect(assignment_day.activities_and_assessment_count_label).to include '1 another_type'
      end
    end
  end
end
