describe CalendarPresenter do
  describe '#show_estimated_times?' do
    let(:course) { build_stubbed(:course) }
    let(:section) { build_stubbed(:section, :course => course) }
    let(:user) { build_stubbed(:user) }
    let(:calendar_presenter) do
      described_class.new(
        user,
        Date.today,
        build_stubbed(:program),
        section: section
      )
    end

    it "returns true, when user is an instructor" do
      allow(user).to receive(:instructor?).and_return(true)
      expect(calendar_presenter.show_estimated_times?).to be_truthy
    end

    context "when user is not an instructor" do
      before do
        allow(user).to receive(:instructor?).and_return(false)
      end
      it "returns true , when show_estimated_times is true on the course" do
        expect(calendar_presenter.show_estimated_times?).to be_truthy
      end

      it "returns false, when show_estimated_times is false on the course" do
        allow(course).to receive(:show_estimated_times?).and_return(false)
        expect(calendar_presenter.show_estimated_times?).to be_falsey
      end
    end
  end

  context "with invalid params" do
    it "should raise exception if both section and focus are passed" do
      user = build_stubbed(:instructor)
      program = build_stubbed(:program)
      focus = Focus.new(user, program)
      section = build_stubbed(:section)
      expect{ calendar_presenter = CalendarPresenter.new(user, nil, build_stubbed(:program), {:section => section, :focus => focus}) }.to raise_error 'You can only specify a Section or Focus, but not both.'
    end

    it "should raise error if the section param is not a section object" do
      user = build_stubbed(:instructor)
      expect{ calendar_presenter = CalendarPresenter.new(user, nil, build_stubbed(:program), {:section => nil}) }.to raise_error ':section must be an object of type Section.'
    end

    it "should raise error if focus param is not a focus object" do
      user = build_stubbed(:instructor)
      expect{ calendar_presenter = CalendarPresenter.new(user, nil, build_stubbed(:program), {:focus => nil}) }.to raise_error ':focus must be an object of type Focus.'
    end
  end

  describe ".build" do
    it "builds calendar data on presenter object  " do
      cal_presenter = double('cal_presenter')
      allow(CalendarPresenter).to receive(:new).and_return(cal_presenter)
      expect(cal_presenter).to receive(:build_calendar)
      CalendarPresenter.build([])
    end

    it "returns a new presenter object" do
      cal_presenter = double('cal_presenter')
      allow(CalendarPresenter).to receive(:new).and_return(cal_presenter)
      allow(cal_presenter).to receive(:build_calendar)
      expect(CalendarPresenter.build([])).to eql(cal_presenter)
    end
  end

  describe '#build_calendar' do
    let(:section) do
      create(
        :section,
        course: create(
          :course,
          start_date: 2.months.ago,
          end_date: 2.months.from_now
        ),
        class_days: '1,2,3'
      )
    end

    let(:presenter) do
      described_class.new(
        user,
        Date.today,
        create(:program),
        section: section
      )
    end

    let(:event_calendar) do
      instance_double(EventCalendar, month: Date.today.month)
    end

    let(:user) { create(:student) }
    let(:sections) { [section] }
    let(:start_date) { Date.today.beginning_of_month }
    let(:end_date) { Date.today.end_of_month }

    before do
      allow(EventCalendar).to receive(:new).and_return(event_calendar)
      allow(presenter).to receive(:sections).and_return(sections)
      allow(event_calendar).to receive(:beginning_of_month)
        .and_return(start_date)
      allow(event_calendar).to receive(:end_of_month)
        .and_return(end_date)
      allow(event_calendar).to receive(:populate_categories)
      allow(event_calendar).to receive(:<<)
    end

    it 'adds assignments only for the specified section and month' do
      create(
        :assignment,
        due_date: (start_date - 2.days),
        section: section
      )
      create(
        :assignment,
        due_date: (end_date + 2.days),
        section: section
      )
      create(
        :assignment,
        due_date: (start_date + 2.days),
        section: create(:section)
      )
      valid_assignment = create(
        :assignment,
        due_date: (start_date + 2.days),
        section: section
      )
      presenter.build_calendar

      expect(event_calendar).to have_received(:<<).once
      expect(event_calendar).to have_received(:<<).with(valid_assignment)
    end

    it 'optionally skips assignments' do
      create(
        :assignment,
        due_date: (start_date + 2.days),
        section: section
      )
      presenter.build_calendar(skip_assignments: true)

      expect(event_calendar).not_to have_received(:<<)
    end

    it 'populates the category labels' do
      presenter.build_calendar

      expect(event_calendar).to have_received(:populate_categories)
    end

    context 'when there are individually-assignable assignments in the ' \
            'specified month,' do
      let!(:assignment_1) do
        create(
          :assignment,
          due_date: (start_date + 2.days),
          individually_assignable: true,
          section: section
        )
      end

      let!(:assignment_2) do
        create(
          :assignment,
          due_date: (start_date + 2.days),
          individually_assignable: false,
          section: section
        )
      end

      # rubocop:disable RSpec/MultipleExpectations
      # There's no way to use have_received to validate that multiple calls
      # are made ONLY with the expected arguments. So separate expectations
      # are needed to validate the count and then the arguments.
      context 'when user is an instructor,' do
        let(:user) { create(:instructor) }

        it 'returns assignments regardless of their individually-assignable ' \
           'status' do
          presenter.build_calendar

          expect(event_calendar).to have_received(:<<).twice
          expect(event_calendar).to have_received(:<<).with(assignment_1)
          expect(event_calendar).to have_received(:<<).with(assignment_2)
        end
      end

      context 'when user is a student,' do
        let(:user) { create(:student) }

        it 'returns individually-assigned assignments if they are assigned ' \
           'to that student' do
          presenter.build_calendar

          expect(event_calendar).to have_received(:<<).once
          expect(event_calendar).to have_received(:<<).with(assignment_2)
        end

        it 'does not return indvidually-assigned assignments if they are ' \
           'not assigned to that student' do
          IndividualAssignment.create!(
            activity_id: assignment_1.assignable_id,
            section_id: section.id,
            user_id: user.id
          )

          presenter.build_calendar

          expect(event_calendar).to have_received(:<<).twice
          expect(event_calendar).to have_received(:<<).with(assignment_1)
          expect(event_calendar).to have_received(:<<).with(assignment_2)
        end
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context 'when there are activities with custom due dates assigned ' \
            'in the specified month,' do
      context 'when user is a student,' do
        let(:user) { create(:student) }
        let(:due_date_outside_month) { start_date + 45.days }
        let(:due_date_inside_month) { start_date + 2.days }

        it 'retrieves assignments only if their custom due date for the ' \
           'current student is within the specified month' do
          # The default due date for assignment_1 is within the specified
          # month, but the custom due date is outside it.
          assignment_1 = create(
            :assignment,
            due_date: due_date_inside_month,
            individually_assignable: true,
            section: section
          )
          IndividualAssignment.create!(
            activity_id: assignment_1.assignable_id,
            due_date: due_date_outside_month,
            section_id: section.id,
            user_id: user.id
          )

          # The default due date for assignment_2 is outside the specified
          # month, but the custom due date is inside it.
          assignment_2 = create(
            :assignment,
            due_date: due_date_outside_month,
            individually_assignable: false,
            section: section
          )
          IndividualAssignment.create!(
            activity_id: assignment_2.assignable_id,
            due_date: due_date_inside_month,
            section_id: section.id,
            user_id: user.id
          )

          presenter.build_calendar

          expect(event_calendar).not_to have_received(:<<).with(assignment_1)
          expect(event_calendar).to have_received(:<<).with(
            have_attributes(
              id: assignment_2.id,
              # The due_date attribute on the assignment record should be
              # the custom due date.
              due_date: due_date_inside_month
            )
          )
        end
      end
    end
  end

  describe '#items_by_date' do
    let(:user) { build_stubbed(:instructor) }
    let(:program) { create(:program) }
    let(:course) { create(:course, program: program) }

    let(:section) do
      create(:section, course: course, days_to_show_assignment_due_date: 4)
    end

    let(:focus_opts) do
      {
        program.id.to_s => {
          'course_id' => course.id, 'section_id' => section.id
        }
      }
    end

    let(:focus) { Focus.new(user, program, focus_opts) }
    let(:today) { Date.today }

    let(:presenter) do
      described_class.new(user, today, program, focus: focus)
    end

    let(:calendar_settings) do
      double('calendar_settings', start_date: today, sections: [section])
    end

    let(:event_calendar) do
      instance_double(EventCalendar, month: today.month, year: today.year)
    end

    let(:monthly_assignment_list) do
      instance_double(MonthlyAssignmentList, assignments: {})
    end

    before do
      allow(CalendarPresenter::CalendarSettings).to receive(:new).and_return(calendar_settings)
      allow(EventCalendar).to receive(:new).and_return(event_calendar)
      allow(Announcement).to receive(:by_month_and_calendar_day).and_return({})
      allow(MonthlyAssignmentList).to receive(:new).and_return(
        monthly_assignment_list
      )
    end

    it 'instantiates a MonthlyAssignmentList instance' do
      presenter.items_by_date

      expect(MonthlyAssignmentList).to have_received(:new).with(
        today.month, today.year, [section], user
      )
    end

    it 'fetches the assignments from the MonthlyAssignmentList instance' do
      presenter.items_by_date

      expect(monthly_assignment_list).to have_received(:assignments)
    end

    it 'returns the assignments from the MonthlyAssignmentList instance' do
      assignments = { 123 => 456 }
      allow(monthly_assignment_list).to receive(:assignments)
        .and_return(assignments)
      expect(presenter.items_by_date[:assignments]).to eq(assignments)
    end

    context 'when user is an instructor' do
      it 'returns announcements for the given month number and the sections ' \
         'set by focus' do
        presenter.items_by_date[:announcements]

        expect(Announcement).to have_received(:by_month_and_calendar_day)
          .with(focus.sections, event_calendar.month)
      end
    end

    context 'when user is a student' do
      it 'returns announcements for the given month number and the section ' \
         'passed to the presenter' do
        student = build_stubbed(:student)
        presenter = described_class.new(student, today, program, section: section)
        presenter.items_by_date[:announcements]
        expect(Announcement).to have_received(:by_month_and_calendar_day)
          .with([section], event_calendar.month)
      end
    end
  end

  describe ".event_calendar" do
    context "with valid params" do
      it "should return an EventCalendar object if user and section are passed" do
        course = build_stubbed(:course)
        section = build_stubbed(:section, :course => course)
        user = build_stubbed(:student)
        calendar_presenter = CalendarPresenter.new(user, Date.today, build_stubbed(:program), {:section => section})
        expect(calendar_presenter.event_calendar).to be_a(EventCalendar)
      end

      it "should return an EventCalendar object if user and focus are passed" do
        user = build_stubbed(:instructor)
        program = build_stubbed(:program)
        focus = Focus.new(user, program)
        allow(focus).to receive(:course_start_date).and_return(2.days.ago.to_date)
        allow(focus).to receive(:course_end_date).and_return(2.days.from_now.to_date)
        allow(focus).to receive(:type).and_return('section')
        allow(focus).to receive(:course).and_return( build_stubbed(:course) )
        allow(focus).to receive(:sections).and_return( [build_stubbed(:section)] )
        allow(focus).to receive(:class_days).and_return( ['1','2','3'] )
        calendar_presenter = CalendarPresenter.new(user, Date.today, build_stubbed(:program), {:focus => focus})
        expect(calendar_presenter.event_calendar).to be_a(EventCalendar)
      end
    end
  end

  describe '#has_multiple_due_dates?' do
    let(:section) do
      create(
        :section,
        course: create(
          :course,
          start_date: 2.months.ago,
          end_date: 2.months.from_now
        ),
        class_days: '1,2,3'
      )
    end

    let(:section_other_course) do
      create(:section)
    end

    let(:student) { create(:student) }
    let(:instructor) { create(:instructor) }

    let(:student_presenter) do
      described_class.new(
        student,
        Date.today,
        create(:program),
        section: section
      )
    end

    let(:instructor_presenter) do
      described_class.new(
        instructor,
        Date.today,
        create(:program),
        section: section
      )
    end

    let(:sections) { [section] }
    let(:date) { 7.days.from_now.to_date }
    let(:other_date) { 4.days.from_now.to_date }
    let(:date_other_course) { 9.days.from_now.to_date }
    let(:other_date_other_course) { 10.days.from_now.to_date }

    let(:assignment) do
      create(
        :assignment,
        due_date: date,
        individually_assignable: true,
        section: section
      )
    end

    let(:assignment_other_date) do
      create(
        :assignment,
        due_date: other_date,
        individually_assignable: true,
        section: section
      )
    end

    let(:individual_assignment_date_as_custom_date) do
      create(
        :individual_assignment,
        activity_id: assignment_other_date.assignable_id,
        due_date: date,
        section_id: section.id,
        user_id: create(:user).id
      )
    end

    let(:individual_assignment_custom_date_equals_default) do
      create(
        :individual_assignment,
        activity_id: assignment.assignable_id,
        due_date: date,
        section_id: section.id,
        user_id: create(:user).id
      )
    end

    let(:individual_assignment_custom_date_different) do
      create(
        :individual_assignment,
        activity_id: assignment.assignable_id,
        due_date: other_date,
        section_id: section.id,
        user_id: create(:user).id
      )
    end

    let(:assignment_other_course) do
      create(
        :assignment,
        due_date: date_other_course,
        individually_assignable: true,
        section: section_other_course
      )
    end

    let(:individual_assignment_other_course) do
      create(
        :individual_assignment,
        activity_id: assignment_other_course.assignable_id,
        due_date: other_date_other_course,
        section_id: section_other_course.id,
        user_id: create(:user).id
      )
    end

    context 'when there are no assignments for date' do
      it 'returns false if date is neither default nor custom due date' do
        expect(instructor_presenter.has_multiple_due_dates?(date)).to be(false)
      end

      it 'returns false if date is custom due date only' do
        individual_assignment_date_as_custom_date
        expect(instructor_presenter.has_multiple_due_dates?(date)).to be(false)
      end
    end

    context 'when date is default due date for an assignment' do
      it 'returns false if there are no individual assignments for assignment' do
        assignment
        expect(instructor_presenter.has_multiple_due_dates?(date)).to be(false)
      end

      it 'returns false if individual assignment custom due date is same as date (edge case)' do
        individual_assignment_custom_date_equals_default
        expect(instructor_presenter.has_multiple_due_dates?(date)).to be(false)
      end

      context 'when individual assignment custom due date differs from date' do
        before do
          individual_assignment_custom_date_different
        end

        it 'returns true if user is instructor' do
          expect(instructor_presenter.has_multiple_due_dates?(date)).to be(true)
        end

        it 'returns false if user is student' do
          expect(student_presenter.has_multiple_due_dates?(date)).to be(false)
        end

        context 'when assignments are not in sections covered by presenter' do
          it 'returns false' do
            assignment_other_course
            individual_assignment_other_course
            expect(instructor_presenter.has_multiple_due_dates?(date_other_course)).to be(false)
          end
        end
      end
    end
  end

  describe described_class::CalendarSettings do
    describe '#clickable_category_links?' do
      it 'is true for an instructor' do
        calendar_settings = described_class.new(is_instructor: true)

        expect(calendar_settings).to be_clickable_category_links
      end

      context 'with a student,' do
        it 'is true is the program is neither Vista Online Learning or ' \
           'Supersite Junior' do
          program = build_stubbed(:program)

          calendar_settings = described_class.new(
            is_instructor: false, program: program
          )
          expect(calendar_settings).to be_clickable_category_links
        end

        it 'is false if the program is Vista Online Learning' do
          program = build_stubbed(:vol_program)

          calendar_settings = described_class.new(
            is_instructor: false, program: program
          )
          expect(calendar_settings).not_to be_clickable_category_links
        end

        it 'is false if the program is Supersite Junior' do
          program = build_stubbed(:ss_jr_program)

          calendar_settings = described_class.new(
            is_instructor: false, program: program
          )
          expect(calendar_settings).not_to be_clickable_category_links
        end
      end
    end
  end
end
