describe AssignmentHelper do

  include AssignmentHelper
  include ProgramHelper
  include ApplicationHelper

  describe "#format_assignment_description" do
    it "returns the activity title" do
      activity = build_stubbed(:activity)
      assignment = build_stubbed(:assignment, :assignable => activity)
      expect(format_assignment_description(assignment)).to eql(activity.title)
    end
  end

  describe "#format_grade_availability_text" do
    it "should return 'Students will be able to see their grades when I release them' if availability is set to 'on_release'" do
      activity = build_stubbed(:activity)
      assignment = build_stubbed(:assignment, :assignable => activity, :grade_availability => 'on_release')
      expect(format_grade_availability_text(assignment.grade_availability, nil, nil)).to eql 'Students will be able to see their grades when I release them'
    end

    it "should return 'Students will be able to see their grades after <due_date>' if availability is set to 'on_due_date'" do
      activity = build_stubbed(:activity)
      due_date = Time.now
      assignment = build_stubbed(:assignment, :assignable => activity, :grade_availability => 'on_due_date', :due_date => due_date)
      expect(format_grade_availability_text(assignment.grade_availability, nil, due_date)).to eql "Students will be able to see their grades after #{due_date.strftime("%a, %b #{due_date.day.ordinalize} %I:%M %p")}"
    end

    it "should return 'Students will be able to see their grades after <specific_date>' if availability is set to 'on_specific_date'" do
      activity = build_stubbed(:activity)
      specific_date = Time.now
      assignment = build_stubbed(:assignment, :assignable => activity, :grade_availability => 'on_specific_date', :grades_available_at => specific_date)
      expect(format_grade_availability_text(assignment.grade_availability, specific_date, nil)).to eql "Students will be able to see their grades after #{specific_date.strftime("%a, %b #{specific_date.day.ordinalize} %I:%M %p")}"
    end

    it "should return default text if if availability is set to 'on_specific_date' but date value is missing" do
      activity = build_stubbed(:activity)
      specific_date = nil
      assignment = build_stubbed(:assignment, :assignable => activity, :grade_availability => 'on_specific_date', :grades_available_at => specific_date)
      expect(format_grade_availability_text(assignment.grade_availability, specific_date, nil)).to eql "Students will be able to see their grades when all students have been graded"
    end

    it "should return 'Students will be able to see their grades never' if availability is set to 'never'" do
      activity = build_stubbed(:activity)
      assignment = build_stubbed(:assignment, :assignable => activity, :grade_availability => 'never')
      expect(format_grade_availability_text(assignment.grade_availability, nil, nil)).to eql 'Students will be able to see their grades never'
    end

    it "should return 'Students will be able to see their grades when all students have been graded' if availability is set to 'on_grading'" do
      activity = build_stubbed(:activity)
      assignment = build_stubbed(:assignment, :assignable => activity, :grade_availability => 'on_grading')
      expect(format_grade_availability_text(assignment.grade_availability, nil, nil)).to eql 'Students will be able to see their grades when all students have been graded'
    end

    it "should return 'Students will be able to see their grades when all students have been graded' if availability is not set" do
      activity = build_stubbed(:activity)
      assignment = build_stubbed(:assignment, :assignable => activity)
      expect(format_grade_availability_text(assignment.grade_availability, nil, nil)).to eql 'Students will be able to see their grades when all students have been graded'
    end
  end

  describe "#format_toc_assignment_info" do
    before(:each) do
      sections = []
      (0..3).each do |idx|
        sections << build_stubbed(:section, :name => "Section #{idx}")
      end
      @assignments = []
      (0..3).each do |idx|
        @assignments << build_stubbed(:assignment, :due_date => idx.days.from_now.to_date,
                                                  :section => sections[idx],
                                                  :assignable_id => 1)
      end
    end
    it "should return an unordered list" do
      expect(format_toc_assignment_info(@assignments)).to include '<ul>'
    end

    it "should include the due dates and section names" do
      results = format_toc_assignment_info(@assignments)
      (0..3).each do |idx|
        expected_date = format_toc_due_date(@assignments[idx]).gsub(/<.+?>/, '')
        expected_section = @assignments[idx].section.name
        expect(results).to have_selector('li', text: expected_date)
        expect(results).to have_selector('li', text: expected_section)
      end
    end
  end

    describe "#format_toc_due_date" do
    it "should return a blank div if there are no assignments" do
      activity = build_stubbed(:activity)
      assignments = []
      expect(format_toc_due_date(assignments))
        .to have_selector('div[class=toc_activity_due_date][id=toc_activity_due_date_]',
                          text: '')

      assignments = nil
      expect(format_toc_due_date(assignments))
        .to have_selector('div[class=toc_activity_due_date][id=toc_activity_due_date_]',
                          text: '')
    end

    it "should return a date string if the activity is assigned" do
      activity = build_stubbed(:activity)
      assignment = build_stubbed(:assignment, :due_date => 5.days.from_now.to_date, :assignable_id => activity.id, :assignable_type => 'Activity')
      results = format_toc_due_date(assignment)
      expect(results.match(/\w+ \d\d\/\d\d/)).to be_truthy
    end

    it "should return 'varies' if the activity is assigned in more than one section and date" do
      section = create(:section)
      assignments = [build_stubbed(:assignment, :due_date => Time.now.to_date,
                                               :section => section,
                                               :assignable_id => 123,
                                               :assignable_type => 'Activity'),
                     build_stubbed(:assignment, :due_date => 1.day.from_now.to_date,
                                               :section => section,
                                               :assignable_id => 123,
                                               :assignable_type => 'Activity')
                    ]
      results = format_toc_due_date(assignments)
      expect(results.match(/varies/)).to be_truthy
    end
  end

  describe "#format_due_date_if_late" do
    context "when due date has passed" do
      before(:each) do
        @due_date = 2.days.ago
      end

      it "should display the date normally if not submitted late" do
        results = format_due_date_if_late(@due_date, 'my_date', :complete)
        expect(results).not_to have_selector('span.overdue_assignment_date')
      end

      it "should display the date normally if incomplete" do
        results = format_due_date_if_late(@due_date, 'my_date', :incomplete)
        expect(results).not_to have_selector('span.overdue_assignment_date')
      end

      it "should display the date as overdue if not opened" do
        results = format_due_date_if_late(@due_date, 'my_date', :unopened)
        expect(results).to have_selector('span.overdue_assignment_date')
      end

      it "should display the date as overdue if opened but not submitted" do
        results = format_due_date_if_late(@due_date, 'my_date', :opened)
        expect(results).to have_selector('span.overdue_assignment_date')
      end

      it "should display the date as overdue if reset" do
        results = format_due_date_if_late(@due_date, 'my_date', :reset)
        expect(results).to have_selector('span.overdue_assignment_date')
      end
    end
  end

  describe "#assignment_by_due_date" do
    it "should return an array sorted by due dates" do
      activity = build_stubbed(:activity)
      section_1 = build_stubbed(:section)
      section_2 = build_stubbed(:section)

      assignment_1_due = 2.days.ago
      assignment_1 = build_stubbed(:assignment ,
                                  :due_date => assignment_1_due,
                                  :section => section_1,
                                  :assignable => activity)
      allow(assignment_1).to receive(:section).and_return(section_1)
      assignment_2_due = 1.days.ago

      assignment_2 = build_stubbed(:assignment ,
                                  :due_date => assignment_2_due,
                                  :section => section_2,
                                  :assignable => activity)
      allow(assignment_2).to receive(:section).and_return(section_2)

      sections = [section_1,section_2]
      assignments = [assignment_1,assignment_2]
      results = assignment_by_due_date(sections,assignments,activity)

      expect(results.first).not_to be_nil
      expect(results.first[:due_date]).to eql(assignment_1_due.to_date.to_s)
      expect(results.first[:sections]).to eql([section_1])
      expect(results.last).not_to be_nil
      expect(results.last[:due_date]).to eql(assignment_2_due.to_date.to_s)
      expect(results.last[:sections]).to eql([section_2])
    end

    it "should return appropriate array when same due date has mulitple section" do
      activity = build_stubbed(:activity)
      section_1 = build_stubbed(:section)
      section_2 = build_stubbed(:section)

      assignment_1_due = 2.days.ago
      assignment_1 = build_stubbed(:assignment ,
                                  :due_date => assignment_1_due,
                                  :section => section_1,
                                  :assignable => activity)
      allow(assignment_1).to receive(:section).and_return(section_1)
      assignment_2 = build_stubbed(:assignment ,
                                  :due_date => assignment_1_due,
                                  :section => section_2,
                                  :assignable => activity)
      allow(assignment_2).to receive(:section).and_return(section_2)

      sections = [section_1,section_2]
      assignments = [assignment_1,assignment_2]
      results = assignment_by_due_date(sections,assignments,activity)

      expect(results.first).not_to be_nil
      expect(results.first[:due_date]).to eql(assignment_1_due.to_date.to_s)
      expect(results.first[:sections]).to eql([section_1,section_2])
    end
  end

  describe "#format_assessment_strand_label" do
    it "should return empty if assignment is empty" do
      assignment = nil
      expect(format_assessment_strand_label(assignment)).to eql ''
    end

    it "should return the strand singular label" do
      activity = build_stubbed(:activity)
      allow(activity).to receive(:strand_singular_label).and_return('strand_label_activity')
      section_1 = build_stubbed(:section)
      assignment = build_stubbed(:assignment , :section => section_1, :assignable => activity)
      expect(format_assessment_strand_label(activity)).to eql activity.strand_singular_label.capitalize
    end
  end

  describe '#category_for_assignment' do
    let(:program_id) { 79 }
    let(:course) { build_stubbed(:course) }
    let(:category) { double('Category', id: 2, name: 'Category 1') }

    context 'when course has no categories' do
      it 'returns a link to the gradebook step of the course wizard (add category)' do
        expect(category_for_assignment([], program_id, course))
          .to eq "<a data-link-type=\"edit course\" href=\"/instructor/#{program_id}/courses/#{course.id}/edit#/gradebook\"" \
                 ">add category</a>"
      end
    end

    context 'when course has one category' do
      let(:categories) { [category] }

      it 'returns the category name' do
        expect(category_for_assignment(categories, program_id, course)).to include category.name
      end

      it 'returns a hidden field with the category id as its value' do
        expect(category_for_assignment(categories, program_id, course))
          .to have_selector("input[id=activity_assignment_category_id][name='activity_assignment[category_id]'][type=hidden][value='#{category.id}']")

      end
    end

    context 'when course has more than one category' do
      let(:another_category) { double('Category', id: 2, name: 'Category 2') }
      let(:categories) { [category, another_category] }

      it 'returns a dropdown' do
        expect(category_for_assignment(categories, program_id, course))
          .to have_selector('select[id=activity_assignment_category_id][name="activity_assignment[category_id]"]')
      end

      it 'returns an option for each course category' do
        output = category_for_assignment(categories, program_id, course)
        categories.each do |category|
          expect(output).to include "<option value=\"#{category.id}\">#{category.name}</option>"
        end
      end
    end
  end
end
