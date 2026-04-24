describe EventDay do
  before do
    course = build_stubbed(:course)
    @calendar_settings = CalendarPresenter::CalendarSettings.new(
      end_date: 3.months.from_now.to_date,
      sections: [build_stubbed(:section, course:), build_stubbed(:section, course:)],
      start_date: 1.month.ago.to_date
    )
  end

  describe '#<<' do
    before do
      @concept = create(:concept)
      activities = [].fill(0..1) { |n| create(:activity, concept: @concept) }
      events = [
        create(:assignment, due_date: Date.today, assignable: activities[0], rank: 10),
        create(:assignment, due_date: Date.today, assignable: activities[1], rank: 20)
      ]
      @event_day = EventDay.new(date: Date.today, calendar_settings: @calendar_settings)
      events.each do |event|
        @event_day << event
      end
    end

    it "should add events in order received" do
      expect(@event_day.events[0].rank).to eq(10)
      expect(@event_day.events[1].rank).to eq(20)
    end

    context "when assignment that is not related to an assessment is passed" do
      it "should not populate the assessments array" do
        activity = build_stubbed(:activity)
        allow(activity).to receive(:assessment?).and_return(false)
        assignment = build_stubbed(:assignment, due_date: Date.today, assignable: activity)
        @event_day << assignment
        expect(@event_day.assessment_links.size).to eq(0)
      end
    end

    context "when assignment that is related to an assessment is passed" do
      it "should populate the assessments array" do
        assessment = build_stubbed(:activity)
        allow(assessment).to receive(:assessment?).and_return(true)
        assignment = build_stubbed(:assignment, due_date: Date.today, assignable: assessment)
        @event_day << assignment
        expect(@event_day.assessment_links.size).to eq(1)
      end
    end
  end

  describe "#banks" do
    it "returns a bank for each group of activities" do
      concept1 = create(:concept, :name => 'concept1')
      concept2 = create(:concept, :name => 'concept2')

      group1 = [].fill(0..1) { |n| create(:activity, :concept => concept1,
                                                      :minutes_to_complete => 8) }
      group2 = [].fill(0..2) { |n| create(:activity, :concept => concept2,
                                                      :minutes_to_complete => 9) }
      group3 = [].fill(0..3) { |n| create(:activity, :concept => concept1,
                                                      :minutes_to_complete => 8) }

      @event_day = EventDay.new(:due_date => Date.today, :calendar_settings => @calendar_settings)
      @event_day.lesson_plan_groups = [group1, group2, group3]

      # expected results
      bank_vals = Array.new
      bank_vals << { 'concept' => concept1, 'assigned_count' => 2, 'assigned_minutes' => 20 }
      bank_vals << { 'concept' => concept2, 'assigned_count' => 3, 'assigned_minutes' => 30 }
      bank_vals << { 'concept' => concept1, 'assigned_count' => 4, 'assigned_minutes' => 35 }

      @event_day.banks.each_with_index do |bank, index|
        expect(bank.class).to eq(Bank)
        expect(bank.concept).to eq(bank_vals[index]['concept'])
        expect(bank.assigned_count).to eq(bank_vals[index]['assigned_count'])
        expect(bank.assigned_minutes).to eq(bank_vals[index]['assigned_minutes'])
      end

      expect(@event_day.total_minutes).to eq(20 + 30 + 35)
      expect(@event_day.total_activities).to eq(2 + 3 + 4)
    end
  end

  describe "#concepts" do
    it "returns concepts, preserving event order" do
      concept1 = create(:concept, :name => 'concept1')
      concept2 = create(:concept, :name => 'concept2')
      concept3 = create(:concept, :name => 'concept3')

      bank1 = double(Bank, :concept => concept1)
      bank2 = double(Bank, :concept => concept2)
      bank3 = double(Bank, :concept => concept3)

      @event_day = EventDay.new(:calendar_settings => @calendar_settings)
      allow(@event_day).to receive(:banks).and_return([bank1, bank2, bank3])
      expect(@event_day.concepts).to eq([concept1, concept2, concept3])

      allow(@event_day).to receive(:banks).and_return([bank3, bank1, bank2])
      expect(@event_day.concepts).to eq([concept3, concept1, concept2])
    end
  end

  describe "#activities" do
    before (:each) do
      @event_day = EventDay.new(:calendar_settings => @calendar_settings)
    end

    context "when there are lesson plan groups," do
      it "flattens the lesson plan groups and returns activities" do
        concept1 = create(:concept, :name => 'concept1')
        concept2 = create(:concept, :name => 'concept2')

        group1 = [].fill(0..1) { |n| create(:activity, :concept => concept1,
                                                        :minutes_to_complete => 8) }
        group2 = [].fill(0..2) { |n| create(:activity, :concept => concept2,
                                                        :minutes_to_complete => 9) }

        @event_day.lesson_plan_groups = [group1,group2]

        activities = @event_day.activities

        expect(activities.first).to eq(group1.first)
        expect(activities.last).to eq(group2.last)
        expect(activities.count).to eq(group1.count + group2.count)
      end
    end

    context "when there are no lesson plan groups," do
      it "loops through the events, returning the activities for the events that are assignments in order" do
        @event_day.lesson_plan_groups = []

        @event_day.events << create(:assignment, assignable: create(:activity, title: 'act1'), rank: 1)
        @event_day.events << create(:assignment, assignable: create(:activity, title: 'act2'), rank: 2)

        results = @event_day.activities

        expect(results.first.title).to eq('act1')
        expect(results.last.title).to  eq('act2')
      end
    end
  end

  describe "#class_day?" do
    let(:course_start_date) { 1.month.ago.to_date }
    let(:course_end_date) { 3.months.from_now.to_date }
    let(:section) { build_stubbed(:section_with_course) }
    let(:all_days_of_week) { ['0', '1', '2', '3', '4', '5', '6'] }
    let(:monday_and_wednesday) { ['1','3'] }

    before do
      @calendar_settings_options = { :start_date => course_start_date,
                                     :end_date => course_end_date,
                                     :sections => [section],
                                     :course => section.course }
    end

    context 'when classes take place every day of the week' do
      it 'returns false if the day is before the course start date' do
        calendar_settings = CalendarPresenter::CalendarSettings.new( @calendar_settings_options.merge(:class_days => all_days_of_week) )
        event_day = EventDay.new(:date => course_start_date - 1.day, :calendar_settings => calendar_settings)
        expect(event_day.class_day?).to be_falsey
      end

      it 'returns false if the day is after the course end date' do
        calendar_settings = CalendarPresenter::CalendarSettings.new( @calendar_settings_options.merge(:class_days => all_days_of_week) )
        event_day = EventDay.new(:date => course_end_date + 1.day, :calendar_settings => calendar_settings)
        expect(event_day.class_day?).to be_falsey
      end

      it 'returns true if the class takes place between the course start and end date' do
        calendar_settings = CalendarPresenter::CalendarSettings.new( @calendar_settings_options.merge(:class_days => all_days_of_week) )
        event_day = EventDay.new(:date => course_start_date + 1.day, :calendar_settings => calendar_settings)
        expect(event_day.class_day?).to be_truthy
        event_day = EventDay.new(:date => course_end_date - 1.day, :calendar_settings => calendar_settings)
        expect(event_day.class_day?).to be_truthy
      end

      it 'return true if the class takes place on the course start_date' do
        calendar_settings = CalendarPresenter::CalendarSettings.new( @calendar_settings_options.merge(:class_days => all_days_of_week) )
        event_day = EventDay.new(:date => course_start_date, :calendar_settings => calendar_settings)
        expect(event_day.class_day?).to be_truthy
      end

      it 'return true if the class takes place on the course end_date' do
        calendar_settings = CalendarPresenter::CalendarSettings.new( @calendar_settings_options.merge(:class_days => all_days_of_week) )
        event_day = EventDay.new(:date => course_end_date, :calendar_settings => calendar_settings)
        expect(event_day.class_day?).to be_truthy
      end
    end

    context 'when classes take place only on certain days of the week' do
      let(:current_day) { Time.local(2012, 06, 24).to_date }
      let(:course_start_date) { current_day - 1.month }
      let(:course_end_date) { current_day + 3.months }

      it 'returns false if the day is before the course start date' do
        Timecop.travel(current_day) do
          calendar_settings = CalendarPresenter::CalendarSettings.new( @calendar_settings_options.merge(:class_days => monday_and_wednesday) )
          event_day = EventDay.new(:date => course_start_date - 1.day, :calendar_settings => calendar_settings)
          expect(event_day.class_day?).to be_falsey
        end
      end

      it 'returns false if the day is after the course end date' do
        Timecop.travel(current_day) do
          calendar_settings = CalendarPresenter::CalendarSettings.new( @calendar_settings_options.merge(:class_days => monday_and_wednesday) )
          event_day = EventDay.new(:date => course_end_date + 1.day, :calendar_settings => calendar_settings)
          expect(event_day.class_day?).to be_falsey
        end
      end

      it 'return true if day is one of the class days of the week' do
        Timecop.travel(current_day) do
          calendar_settings = CalendarPresenter::CalendarSettings.new( @calendar_settings_options.merge(:class_days => monday_and_wednesday) )
          event_day = EventDay.new(:date => Time.local(2012, 06, 25).to_date, :calendar_settings => calendar_settings) # Monday
          expect(event_day.class_day?).to be_truthy
          event_day = EventDay.new(:date => Time.local(2012, 06, 27).to_date, :calendar_settings => calendar_settings) # Wednesday
          expect(event_day.class_day?).to be_truthy
        end
      end

      it 'return false if day is not one of the class days of the week' do
        Timecop.travel(current_day) do
          calendar_settings = CalendarPresenter::CalendarSettings.new( @calendar_settings_options.merge(:class_days => monday_and_wednesday) )
          expect(EventDay.new(:date => Time.local(2012, 06, 24).to_date, :calendar_settings => calendar_settings).class_day?).to be_falsey # Sunday
          expect(EventDay.new(:date => Time.local(2012, 06, 26).to_date, :calendar_settings => calendar_settings).class_day?).to be_falsey # Tuesday
          expect(EventDay.new(:date => Time.local(2012, 06, 28).to_date, :calendar_settings => calendar_settings).class_day?).to be_falsey # Thrusday
          expect(EventDay.new(:date => Time.local(2012, 06, 29).to_date, :calendar_settings => calendar_settings).class_day?).to be_falsey # Friday
          expect(EventDay.new(:date => Time.local(2012, 06, 30).to_date, :calendar_settings => calendar_settings).class_day?).to be_falsey # Saturday
        end
      end
    end
  end

  describe "#css_classes" do
    before(:each) do
      @instructor = build_stubbed(:instructor)
      @event_day = EventDay.new(:date => Date.today,
                                :calendar_settings => double('CalendarSetting', :start_date => '', :end_date => ''))
      allow(@event_day).to receive(:valid_day?).and_return(true)
      allow(@event_day).to receive(:class_day?).and_return(false)
      allow(@event_day).to receive(:today?).and_return(false)
    end

    it "always includes a 'day' class" do
      expect(@event_day.css_classes).to match('day')
    end

    it "includes 'today' when this day is today" do
      allow(@event_day).to receive(:today?).and_return(true)
      expect(@event_day.css_classes).to match('today')
    end

    it "does not include 'today' when this day is not today" do
      allow(@event_day).to receive(:today?).and_return(false)
      expect(@event_day.css_classes).not_to match('today')
    end

    it "includes 'class_day' when class is scheduled on this day" do
      allow(@event_day).to receive(:class_day?).and_return(true)
      expect(@event_day.css_classes).to match('class_day')
    end

    it "does not include 'class_day' when class is not scheduled on this day" do
      allow(@event_day).to receive(:class_day?).and_return(false)
      expect(@event_day.css_classes).not_to match('class_day')
    end

  end

  describe "#update_categories" do
    before(:each) do
      @event_day = EventDay.new(:date => Date.today, :calendar_settings => @calendar_settings)
      allow(@event_day).to receive(:assignments_for_category_of_section)
      @categories = []
      (0..2).each do |idx|
        @categories << build_stubbed(:category)
        (0..idx).each do
          @event_day << build_stubbed(:assignment, :category => @categories.last, :due_date => Date.today)
        end
      end
    end

    it "should create a hash of assignments keyed on category name" do
      @event_day.update_categories(@categories)
      expect(@event_day.category_assignments).to be_a Hash
      expect(@event_day.category_assignments.keys.sort).to eq(@categories.map(&:name).sort)
    end

    it "should create an array of assignments for each category_assignment key" do
      @event_day.update_categories(@categories)
      @event_day.category_assignments.each_pair do |cat_name, assignments|
        expect(assignments).to be_a Array
        expect(assignments.first).to be_a Assignment
      end
    end

    it "should assign categories" do
      @event_day.update_categories(@categories)
      expect(@event_day.categories).to eq(@categories)
    end
  end

  describe "#uniform_assignments_for?" do
    context "when there is only one section" do
      before(:each) do
        section_1 = build_stubbed(:section)
        @calendar_settings = CalendarPresenter::CalendarSettings.new( :user => @instructor, :start_date => 1.month.ago.to_date,
                                                                     :end_date => 3.months.from_now.to_date,
                                                                     :sections => [section_1] )
        @event_day = EventDay.new(:due_date => Date.today, :calendar_settings => @calendar_settings)
      end

      it "should return false" do
        expect(@event_day.uniform_assignments_for?('cat')).to be_truthy
      end
    end

    context "when there are more than one section" do
      before(:each) do
        @section_1 = build_stubbed(:section)
        @section_2 = build_stubbed(:section)

        @activity_1 = build_stubbed(:activity)
        @activity_2 = build_stubbed(:activity)

        @calendar_settings = CalendarPresenter::CalendarSettings.new( :user => @instructor, :start_date => 1.month.ago.to_date,
                                                                     :end_date => 3.months.from_now.to_date,
                                                                     :sections => [@section_1,@section_2] )
        @event_day = EventDay.new(:due_date => Date.today, :calendar_settings => @calendar_settings)
      end

      context "when sections have same assigment sets in category" do
        before(:each) do
          @cat_1 = build_stubbed(:category)
          @cat_2 = build_stubbed(:category)

          assignment_1_1 = build_stubbed(:assignment, :category => @cat_1)
          allow(assignment_1_1).to receive(:section).and_return(@section_1)
          allow(assignment_1_1).to receive(:assignable).and_return(@activity_1)

          assignment_1_2 = build_stubbed(:assignment, :category => @cat_2)
          allow(assignment_1_2).to receive(:section).and_return(@section_1)
          allow(assignment_1_2).to receive(:assignable).and_return(@activity_2)

          assignment_2_1 = build_stubbed(:assignment, :category => @cat_1)
          allow(assignment_2_1).to receive(:section).and_return(@section_2)
          allow(assignment_2_1).to receive(:assignable).and_return(@activity_1)


          assignment_2_2 = build_stubbed(:assignment, :category => @cat_2)
          allow(assignment_2_2).to receive(:section).and_return(@section_2)
          allow(assignment_2_2).to receive(:assignable).and_return(@activity_2)

          @event_day  << assignment_1_1
          @event_day  << assignment_1_2
          @event_day  << assignment_2_1
          @event_day  << assignment_2_2

          @event_day.update_categories([@cat_1,@cat_2])

        end

        it "should return true" do
          expect(@event_day.uniform_assignments_for?(@cat_1)).to be_truthy
        end

      end

      context "when sections have different assigment sets within category but on is empty" do
        before(:each) do
          @cat_1 = build_stubbed(:category)
          @cat_2 = build_stubbed(:category)

          assignment_1 = build_stubbed(:assignment, :category => @cat_1)
          allow(assignment_1).to receive(:section_id).and_return(@section_1.id)
          allow(assignment_1).to receive(:assignable_id).and_return(@activity_1.id)

          @event_day  << assignment_1
          @event_day.update_categories([@cat_1,@cat_2])
        end

        it "should return false" do
          expect(@event_day.uniform_assignments_for?(@cat_1)).to be_falsey
        end
      end

      context "when sections have different assigment sets within category" do
        before(:each) do
          @cat_1 = build_stubbed(:category)
          @cat_2 = build_stubbed(:category)

          assignment_1 = build_stubbed(:assignment, :category => @cat_1)
          allow(assignment_1).to receive(:section_id).and_return(@section_1.id)
          allow(assignment_1).to receive(:assignable_id).and_return(@activity_1.id)

          assignment_2 = build_stubbed(:assignment, :category => @cat_1)
          allow(assignment_2).to receive(:section_id).and_return(@section_2.id)
          allow(assignment_2).to receive(:assignable_id).and_return(@activity_2.id)

          @event_day  << assignment_1
          @event_day  << assignment_2
          @event_day.update_categories([@cat_1,@cat_2])

        end

        it "should return true" do
          expect(@event_day.uniform_assignments_for?(@cat_1)).to be_falsey
        end
      end

    end
  end

  describe "#section_class_days_vary?" do
    context "for a section" do
      it "should return false" do
        course = build_stubbed(:course)
        calendar_settings = CalendarPresenter::CalendarSettings.new( :user => @instructor, :start_date => course.start_date,
                                                                    :end_date => course.end_date,
                                                                    :course => course,
                                                                    :type => 'section' )
        @event_day = EventDay.new(:date => Date.today, :calendar_settings => calendar_settings)
        expect(@event_day.section_class_days_vary?).to be_falsey
      end
    end

    context "for a course where the course's section class days do not vary" do
      it "should return false" do
        course = build_stubbed(:course)
        calendar_settings = CalendarPresenter::CalendarSettings.new( :user => @instructor, :start_date => course.start_date,
                                                                    :end_date => course.end_date,
                                                                    :course => course,
                                                                    :type => 'course',
                                                                    :section_class_days_vary => false )
        @event_day = EventDay.new(:date => Date.today, :calendar_settings => calendar_settings)
        expect(@event_day.section_class_days_vary?).to be_falsey
      end
    end

    context "for a course where the course's section class days do vary" do
      it "should return true" do
        course = build_stubbed(:course)
        calendar_settings = CalendarPresenter::CalendarSettings.new( :user => @instructor, :start_date => course.start_date,
                                                                    :end_date => course.end_date,
                                                                    :course => course,
                                                                    :type => 'course',
                                                                    :section_class_days_vary => true )
        @event_day = EventDay.new(:date => Date.today, :calendar_settings => calendar_settings)
        expect(@event_day.section_class_days_vary?).to be_truthy
      end
    end
  end

  describe '#assessment_links' do
    let(:assessment) { build_stubbed(:activity) }
    let(:course) { build_stubbed(:course) }
    let(:section) { build_stubbed(:section, course: course) }
    let(:html_options) { { class: 'assignment_class' } }

    let(:url_options) do
      {
        action: :show,
        controller: :activities,
        id: assessment.id,
        section_id: section.id
      }
    end

    let(:assignment) do
      build_stubbed(
        :assignment,
        due_date: Date.today,
        assignable: assessment,
        section: section
      )
    end

    let(:event_day) do
      described_class.new(date: Date.today, calendar_settings: calendar_settings)
    end

    before do
      allow(assessment).to receive(:assessment?).and_return(true)
      event_day << assignment
    end

    context 'when an assessment is assigned in one section,' do
      let(:program) { build_stubbed(:program) }

      let(:calendar_settings) do
        CalendarPresenter::CalendarSettings.new(
          assessment_html_options: html_options,
          assessment_link_params: url_options,
          category_html_options: {},
          category_link_params: {},
          class_days: %w[1 2 3],
          course: section.course,
          end_date: section.course.end_date,
          is_instructor: false,
          program: program,
          section_class_days_vary: false,
          sections: [section],
          start_date: section.course.start_date,
          type: 'section',
          user: @instructor
        )
      end

      before do
        allow(assessment).to receive(:accessible_by_section?).and_return(true)
      end

      it 'returns a link to each assigned assessment passed to the event' \
         'with the display_link? property set to true if the program is not ' \
         'a Supersite Junior program' do
        allow(program).to receive(:supersite_junior?).and_return(false)

        expect(event_day.assessment_links).to contain_exactly(
          OpenStruct.new(
            count_label: '',
            display_link?: true,
            html_options: html_options,
            name: assessment.concept.name,
            url_options: url_options
          )
        )
      end

      it 'returns a link to each assigned assessment passed to the event' \
         'with the display_link? property set to false if the program is ' \
         'a Supersite Junior program' do
        allow(program).to receive(:supersite_junior?).and_return(true)

        expect(event_day.assessment_links).to contain_exactly(
          OpenStruct.new(
            count_label: '',
            display_link?: false,
            html_options: html_options,
            name: assessment.concept.name,
            url_options: url_options
          )
        )
      end
    end

    context 'when an assessment is assigned across sections,' do
      let(:section_2) { build_stubbed(:section, course: course) }

      let(:calendar_settings) do
        CalendarPresenter::CalendarSettings.new(
          assessment_html_options: {},
          assessment_link_params: {},
          category_html_options: {},
          category_link_params: {},
          class_days: %w[1 2 3],
          course: section.course,
          end_date: section.course.end_date,
          is_instructor: false,
          section_class_days_vary: false,
          sections: [section, section_2],
          start_date: section.course.start_date,
          type: 'section'
        )
      end

      it 'returns the name of the concept as the label if the activity ' \
         'is assigned for both section' do
        assignment_another_section = build_stubbed(
          :assignment,
          assignable: assessment,
          due_date: Date.today,
          section: section_2
        )
        event_day << assignment_another_section

        expect(event_day.assessment_links.map(&:name)).to contain_exactly(
          assessment.concept.name
        )
      end

      it "returns the label with the postfix 'varies' if the activity is " \
         'assigned in only one section' do
        expect(event_day.assessment_links.map(&:name)).to contain_exactly(
          "#{assessment.concept.name} (varies)"
        )
      end
    end
  end

  describe "#category_links" do
    before(:each) do
      @event_day = EventDay.new(:calendar_settings => @calendar_settings)
      @category_assignments = {}
      @categories = []
      (1..3).each do |index|
        category = build_stubbed(:category)
        assignment = build_stubbed(:assignment)
        lesson_label = "Lección #{index}"
        allow(assignment).to receive(:assignable_lesson_label).and_return(lesson_label)
        @category_assignments.merge!(category.name => [assignment])
        @categories << category
      end

      assignment = build_stubbed(:assignment)
      allow(assignment).to receive(:assignable_lesson_label).and_return('Lección 2')
      @category_assignments[@categories.first.name] << assignment
      @event_day.date = Date.today
      @event_day.categories = @categories
      @event_day.category_assignments = @category_assignments
    end

    it "returns a list of category link structures, one structure by lesson in category" do
      expect(@event_day.category_links.size).to eq(4)
    end

    it "presents the name of the links as Lesson X: Category" do
      expect(@event_day.category_links.first.name).to eq(
        "Lección 1: #{@categories.first.name}"
      )
    end

    context "when an identical assignment is assigned to two different sections in the same category" do
      before(:each) do
        dup_assignment_assignable = @category_assignments[@categories.first.name].first.assignable
        dup_assignment = build_stubbed(:assignment, :assignable => dup_assignment_assignable)
        @category_assignments[@categories.first.name] << dup_assignment
        @event_day.category_assignments = @category_assignments
      end
      it "counts the identical assignments as one assignment (does not double count them)" do
        @event_day.category_links.each do |link|
          expect(link.count_label).to eq(1)
        end
      end
    end

    context "when an assignment is different between sections" do
      before(:each) do
        assignable = build_stubbed(:activity)
        dup_assignment = build_stubbed(:assignment,
                                        assignable: assignable,
                                        section: @calendar_settings.sections.first
                                      )
        @category_assignments[@categories.first.name] << dup_assignment
        @event_day.category_assignments = @category_assignments
      end
      it "it shows 'varies' for the assignment that is different" do
        count_labels = @event_day.category_links.pluck(:count_label)
        expect(count_labels).to include('varies')
      end
    end
  end
end
