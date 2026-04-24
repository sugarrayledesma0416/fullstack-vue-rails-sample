describe TocEntry do

  def create_toc_entry(options)
    entry = TocEntry.new
    entry.title = options[:title] if options[:title]
    entry.short_title = options[:short_title] if options[:short_title]
    entry.children = options[:children] if options[:children]
    entry
  end

  describe "#each" do
    it "traverses toc_entries depth first" do
      grandchild1 = create_toc_entry({:title => 3})
      grandchild2 = create_toc_entry({:title => 4})
      grandchild3 = create_toc_entry({:title => 6})
      grandchild4 = create_toc_entry({:title => 7})

      child1 = create_toc_entry({:title => 2, :children => [grandchild1, grandchild2]})
      child2 = create_toc_entry({:title => 5, :children => [grandchild3, grandchild4]})

      parent = create_toc_entry({:title => 1, :children => [child1, child2]})

      titles = Array.new

      parent.each do |toc_entry|
        titles << toc_entry.title
      end

      expect(titles).to eql([1,2,3,4,5,6,7])
    end
  end

  describe "#display_name" do
    it "should return short_title if valid short_title exists" do
      toc_entry = create_toc_entry(:title => 'long_title', :short_title => 'short_title')
      expect(toc_entry.display_name).to eql("short_title")
    end

    it "should return title if short_title is nil" do
      toc_entry = create_toc_entry(:title => 'long_title', :short_title => nil)
      expect(toc_entry.display_name).to eql("long_title")
    end

    it "should return title if short_title is blank" do
      toc_entry = create_toc_entry(:title => 'long_title', :short_title => '')
      expect(toc_entry.display_name).to eql("long_title")
    end
  end

  describe "#topic_location_in_children?" do
    it 'returns true if strand has substrand at passed in location' do
      child = build_stubbed(:toc_entry)
      location = child.location
      toc_entry = create_toc_entry(:children => [child])
      expect(toc_entry.topic_location_in_children?(location)).to be_truthy
    end
  end

  describe "#activities_list" do
    let(:toc_entry) { create(:toc_entry) }

    context "without a section" do
      it "finds activities with the current toc location" do
        activity = create(:activity, :toc_location => toc_entry.location)
        expect(toc_entry.activities_list(sections: [nil], current_user: nil).to_a).to eql([activity])
      end
    end

    context 'with a section' do
      let(:section) { create(:section) }
      let(:instructor) { section.instructor }
      let(:student) { create(:student) }
      let!(:assigned_activity) do
        assigned_activity = create(
          :activity,
          toc_location: toc_entry.location,
          instructor_revision_id: 1,
          instructor_id: instructor.id
        )
        create(:assignment, assignable: assigned_activity, section:)
        assigned_activity
      end
      let!(:unassigned_activity) do
        create(
          :activity,
          toc_location: toc_entry.location,
          instructor_revision_id: 1,
          instructor_id: instructor.id
        )
      end

      context 'if the activity is assigned' do
        it 'returns the activities regardless of the assigned state, if the ' \
           'current_user is an instructor' do
          expect(
            toc_entry.activities_list(
              sections: [section],
              current_user: instructor
            ).to_a
          ).to match_array [assigned_activity, unassigned_activity]
        end

        it 'returns only the assigned activities, if the current_user is a student' do
          expect(
            toc_entry.activities_list(
              sections: [section],
              current_user: student
            ).to_a
          ).to eq [assigned_activity]
        end
      end
    end
  end

  describe "#descendant_activities" do
    it "return activities for self" do
      entry = create(:toc_entry)
      activity = create(:activity, :toc_location => entry.location)
      expect(entry.descendant_activities).to eql([activity])
    end

    it "return activities for children" do
      child = create(:toc_entry)
      child_activity = create(:activity, :toc_location => child.location)

      parent = create(:toc_entry, :children => [child])
      expect(parent.descendant_activities).to eql([child_activity])
    end

    it "return activities for self, children, and grandchildren" do
      child = create(:toc_entry)
      child_activity = create(:activity, :toc_location => child.location)

      parent = create(:toc_entry, :children => [child])
      parent_activity = create(:activity, :toc_location => parent.location)

      expect(parent.descendant_activities).to eql([parent_activity, child_activity])
    end

    it "returns activities for self, children, and grandchildren that have valid locations" do
      child = create(:toc_entry)
      child_activity = create(:activity, :toc_location => child.location)

      child_without_location = create(:toc_entry, :location => nil)
      child_activity_without_location = create(:activity, :toc_location => child_without_location.location)

      parent = create(:toc_entry, :children => [child, child_without_location])
      parent_activity = create(:activity, :toc_location => parent.location)

      expect(parent.descendant_activities).to eql [parent_activity, child_activity]
    end

    it "returns activities in the order they appear in the toc" do
      child_1 = create(:toc_entry)
      child_1_activity_2 = create(:activity, :toc_location => child_1.location, :toc_location_rank => 2)
      child_1_activity_1 = create(:activity, :toc_location => child_1.location, :toc_location_rank => 1)

      child_2 = create(:toc_entry)
      child_2_activity_2 = create(:activity, :toc_location => child_2.location, :toc_location_rank => 2)
      child_2_activity_1 = create(:activity, :toc_location => child_2.location, :toc_location_rank => 1)

      parent = create(:toc_entry, :children => [child_1, child_2])
      parent_activity = create(:activity, :toc_location => parent.location, :toc_location_rank => 1)

      received_activities = parent.descendant_activities
      expected_activities = [parent_activity, child_1_activity_1, child_1_activity_2, child_2_activity_1, child_2_activity_2]

      expect(received_activities).to eql expected_activities
    end
  end

  describe "#assessment" do
    it "should just be a setter" do
      toc_entry = create(:toc_entry)
      toc_entry.assessment = true
      expect{ toc_entry.assessment }.to raise_error(NoMethodError, /undefined method `assessment'/)
    end
  end

  describe "#assessment?" do
    it "should return false by default" do
      toc_entry = create(:toc_entry)
      expect(toc_entry.assessment?).to be_falsey
    end

    it "should return true if assessment is set to true" do
      toc_entry = create(:toc_entry)
      toc_entry.assessment = true
      expect(toc_entry.assessment?).to be_truthy
    end

    it "should return false if assessment is set to false" do
      toc_entry = create(:toc_entry)
      toc_entry.assessment = false
      expect(toc_entry.assessment?).to be_falsey
    end
  end

end
