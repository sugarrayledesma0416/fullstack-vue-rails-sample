describe Workset, :core => true do

  it "creates a new instance given valid attributes" do
    expect do
      workset = create(:workset)
      expect(workset.errors).to be_empty
    end.to change(Workset, :count)
  end

  it "requires user" do
    expect do
      workset = build(:workset, :user => nil)
      workset.save
      expect(workset.errors[:user_id]).not_to be_empty
    end.not_to change(Workset, :count)
  end

  it "requires section" do
    expect do
      workset = build(:workset, :section => nil)
      workset.save
      expect(workset.errors[:section_id]).not_to be_empty
    end.not_to change(Workset, :count)
  end

  it "requires activity_list to not be empty" do
    expect do
      workset = build(:workset, :activity_list => nil)
      workset.save
      expect(workset.errors[:activity_list]).not_to be_empty
    end.not_to change(Workset, :count)
  end

  describe "#current" do
    before do
      @user = build_stubbed(:user)
      @section = build_stubbed(:section)
      @activity_list = '1,2,3,4'
      Workset.create!(:user => @user, :section => @section, :activity_list => @activity_list)
    end

    it "returns the current workset" do
      @workset = Workset.current(@user, @section)
      expect(@workset).not_to be_nil
      expect(@workset.activity_list).to eql(@activity_list)
    end

    it "returns nil if passed an activity and the activity isn't in the list" do
      @activity = build_stubbed(:activity, :id => 5)
      expect(Workset.current(@user, @section, @activity)).to be_nil
    end
  end

  describe "#activities" do
    it "returns an array of activities in the correct order" do
      user = build_stubbed(:user)
      section = build_stubbed(:section)

      activity_1 = create(:activity)
      activity_2 = create(:activity)
      activity_3 = create(:activity)

      activity_ids = [activity_1.id.to_s, activity_2.id.to_s, activity_3.id.to_s]
      activity_list = activity_ids.join(',')

      workset = Workset.create!(user: user, section: section, activity_list: activity_list)
      unordered_activities = [activity_2, activity_3, activity_1]
      sorted_activities = [activity_1, activity_2, activity_3]
      expect(workset.activities.to_a).to eql(sorted_activities)
    end
  end

  describe 'grouped_activities' do
    let(:user) { create(:user) }
    let(:section) { create(:section) }
    let(:activity_list) { [ 1, 2, 3 ] }
    let(:workset) do
      Workset.create!(
        user: user,
        section: section,
        activity_list: activity_list
      )
    end

    let(:concept_learn) { create(:concept, :name => 'Learn')  }
    let(:concept_practice) { create(:concept, :name => 'Practice')  }

    let(:activity_nil) { create(:activity) }
    let(:activity_learn) do
      create(
        :activity_with_assignment_group,
        assignment_group: 'Learn',
        concept: concept_learn
      )
    end

    let(:activity_practice) do
      create(
        :activity_with_assignment_group,
        assignment_group: 'Practice',
        concept: concept_practice
      )
    end

    let(:assignment_nil) do
      instance_double(
        Assignment,
        assignable: activity_nil
      )
    end

    let(:assignment_1) do
      instance_double(
        Assignment,
        assignable: activity_learn
      )
    end

    let(:assignment_2) do
      instance_double(
        Assignment,
        assignable: activity_practice
      )
    end

    context 'when groups are sorted by assignment group name' do
      it 'returns an array of [activity, assignment] grouped by assignment group' do
        pair_1 = [activity_learn, assignment_1]
        pair_2 = [activity_learn, assignment_1]
        pair_3 = [activity_practice, assignment_2]

        allow(workset).to receive(:activities_and_assignments)
          .and_return([pair_1, pair_2, pair_3])
        allow(workset).to receive(:assignments)
          .and_return([assignment_1, assignment_1, assignment_1])

        learn_group = { name: activity_learn.concept.name, assignments: [pair_1, pair_2] }
        practice_group = { name: activity_practice.concept.name, assignments: [pair_3] }

        expect(workset.grouped_activities(true)).to eql([learn_group, practice_group])
      end
    end

    context 'when there are no groups' do
      it "returns an array of [activity, assignment]" do
        pair = [activity_nil, assignment_nil]
        allow(workset).to receive(:activities_and_assignments).and_return([pair, pair, pair])
        no_groups_group = { name: activity_nil.concept.name, assignments: [pair, pair, pair] }

        expect(workset.grouped_activities(false)).to eql([no_groups_group])
      end
    end

    context 'when there is one group' do
      it 'returns an array with a group that contains a name and assignments' do
        pair = [activity_learn, assignment_1]
        allow(workset).to receive(:activities_and_assignments)
          .and_return([pair, pair, pair])
        learn_group = { name: activity_learn.concept.name, assignments: [pair, pair, pair] }

        expect(workset.grouped_activities(false)).to eql([learn_group])
      end
    end

    context 'when there are multiple groups' do
      it 'returns an array with groups that contain names and assignments' do
        pair_1 = [activity_learn, assignment_1]
        pair_2 = [activity_practice, assignment_1]
        pair_3 = [activity_practice, assignment_2]

        allow(workset).to receive(:activities_and_assignments)
          .and_return([pair_1, pair_2, pair_3])
        allow(workset).to receive(:assignments)
          .and_return([assignment_1, assignment_1, assignment_1])

        learn_group = { name: activity_learn.concept.name, assignments: [pair_1] }
        practice_group = {
          assignments: [pair_2, pair_3],
          name: activity_practice.concept.name
        }

        expect(workset.grouped_activities(false)).to eq([learn_group, practice_group])
      end
    end

    context 'when there are multiple non-sequential groups with the same name' do
      it 'returns an array with distinct groups for each cluster' do
        pair_1 = [activity_learn, assignment_1]
        pair_2 = [activity_practice, assignment_2]
        pair_3 = [activity_learn, assignment_2]

        allow(workset).to receive(:activities_and_assignments)
          .and_return([pair_1, pair_2, pair_3])

        learn_group = { name: activity_learn.concept.name, assignments: [pair_1] }
        practice_group = { name: activity_practice.concept.name, assignments: [pair_2] }
        learn_group_2 = { name: activity_learn.concept.name, assignments: [pair_3] }

        expect(workset.grouped_activities(false))
          .to eql([learn_group, practice_group, learn_group_2])
      end
    end
  end

  describe "#assignment_by_activity" do
    let(:user) { build_stubbed(:user) }
    let(:section) { build_stubbed(:section) }
    let(:activity) { create(:activity) }
    let(:activity_list) { activity.id.to_s }
    let(:workset) { Workset.create!(:user => user, :section => section, :activity_list => activity_list) }

    it "returns the assignment associated with the given activity" do
      assignment = create(:assignment, :assignable => activity)
      allow(workset).to receive(:assignments).and_return([assignment])
      expect(workset.assignment_by_activity(activity)).to eql assignment
    end

    it "returns nil if the activity is not assigned in any of the assignments in the workset" do
      assignment = create(:assignment)
      allow(workset).to receive(:assignments).and_return([assignment])
      expect(workset.assignment_by_activity(activity)).to be_nil
    end
  end

  describe "#attempts" do
    it "returns the attempts for the workset's activities" do
      user = build_stubbed(:user)
      section = build_stubbed(:section)
      attempt = build_stubbed(:attempt)
      activity = create(:activity)
      activity_list = activity.id.to_s

      expect(Attempt).to receive(:attempts_for_activities).with(user, section, [activity]).and_return([attempt])
      workset = Workset.create!(:user => user, :section => section, :activity_list => activity_list)
      expect(workset.attempts).to eql [attempt]
    end
  end

  describe "#attempt" do
    before(:each) do
      @user = build_stubbed(:user)
      @section = build_stubbed(:section)

      @activity_1 = build_stubbed(:activity)
      @activity_2 = build_stubbed(:activity)

      @activities = [@activity_1, @activity_2]
      @activity_list = @activities.collect{|activity| activity.id}.join(',')

      @workset = Workset.create!(:user => @user, :section => @section, :activity_list => @activity_list)
      allow(@workset).to receive(:activities).and_return(@activities)
    end

    it "queries Attempt" do
      expect(Attempt).to receive(:attempts_for_activities).with(@user, @section, @activities).and_return(Hash.new)
      @workset.attempt(@activity_1)
    end

    it "queries Attempt only once, storing the results for the next call" do
      expect(Attempt).to receive(:attempts_for_activities).once.and_return(Hash.new)
      @workset.attempt(@activity_1)
      @workset.attempt(@activity_2)
    end

    it "returns attempts for the provided activites" do
      allow(Attempt).to receive(:attempts_for_activities).and_return({@activity_1.id => 'valid_attempt'})
      expect(@workset.attempt(@activity_1)).to eql('valid_attempt')
    end

  end

  describe "#overdue?" do
    let(:user) { build_stubbed(:user) }
    let(:section) { build_stubbed(:section) }
    let(:activity) { create(:activity) }
    let(:activity_list) { activity.id.to_s }
    let(:workset) { Workset.create!(:user => user, :section => section, :activity_list => activity_list) }

    it "returns true if the assignment is late and the attempt for the activity is unsubmitted" do
      assignment = build_stubbed(:assignment)
      attempt = build_stubbed(:attempt)
      allow(assignment).to receive(:late?).and_return(true)
      allow(workset).to receive(:attempt).and_return(attempt)
      allow(attempt).to receive(:unsubmitted?).and_return(true)
      expect(workset.overdue?(activity, assignment)).to be_truthy
    end

    it "returns false if the assignment is not late" do
      assignment = build_stubbed(:assignment)
      attempt = build_stubbed(:attempt)
      allow(assignment).to receive(:late?).and_return(false)
      allow(workset).to receive(:attempt).and_return(attempt)
      allow(attempt).to receive(:unsubmitted?).and_return(true)
      expect(workset.overdue?(activity, assignment)).to be_falsey
    end

    it "returns false if the attempt for the activity is unsubmitted" do
      assignment = build_stubbed(:assignment)
      attempt = build_stubbed(:attempt)
      allow(assignment).to receive(:late?).and_return(true)
      allow(workset).to receive(:attempt).and_return(attempt)
      allow(attempt).to receive(:unsubmitted?).and_return(false)
      expect(workset.overdue?(activity, assignment)).to be_falsey
    end
  end

  describe "#next_activity" do
    before(:each) do
      @current_activity = build_stubbed(:activity)
    end

    it "returns nil if current activity is not in the workset" do
      @workset = build_stubbed(:workset, :activity_list => "#{(@current_activity.id + 1)}")
      expect(@workset.next_activity(@current_activity)).to be_nil
    end

    it "returns the next activity in the workset if one exists" do
      next_activity = build_stubbed(:activity)
      @workset = build_stubbed(:workset, :activity_list => "#{@current_activity.id},#{next_activity.id}")
      expect(Activity).to receive(:find).with("#{next_activity.id}").and_return(next_activity)
      expect(@workset.next_activity(@current_activity)).to eql(next_activity)
    end

    it "returns last_activity if this is the last activity in the workset" do
      @workset = build_stubbed(:workset, :activity_list => "#{@current_activity.id}")
      expect(@workset.next_activity(@current_activity)).to eql('last_activity')
    end
  end

  describe '#create_or_update' do
    let(:activity_list) { '1,2,3,4' }
    let(:section) { create(:section) }
    let(:user) { create(:user) }

    it 'updates a workset that already exists for a user' do
      workset = described_class.create!(
        activity_list: activity_list,
        section: section,
        user: user
      )

      new_activity_list = '5,6,7,8'
      described_class.create_or_update(user, section, new_activity_list)
      workset.reload
      expect(workset.activity_list).to eql(new_activity_list)
    end

    it 'creates a new workeset when no workset exists for a user' do
      described_class.create_or_update(user, section, activity_list)
      workset = described_class.current(user, section)
      expect(workset.activity_list).to eql(activity_list)
    end
  end

  describe "#final_activity?" do
    before(:each) do
      user = build_stubbed(:user)
      section = build_stubbed(:section)
      activity_list = '1,2,3,4'
      @workset = Workset.create!(:user => user, :section => section, :activity_list => activity_list)
    end

    it "should return true when activity given is final one" do
      activity = build(:activity, :id => 4)

      expect(@workset).to be_final_activity(activity)
    end

    it "should return false when activity given is not the final one." do
      activity = build(:activity, :id => 3)

      expect(@workset.final_activity?(activity)).to be_falsey
    end

    it "should return false when activity given isn't in workset" do
      activity = build(:activity, :id => 6)

      expect(@workset.final_activity?(activity)).to be_falsey
    end
  end
end
