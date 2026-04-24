describe StudentDashboardPresenter do
  include DateTimeHelper

  before do
    @user = create(:student)
    @course = create(:course)
    @section = create(:section, course: @course, time_zone: 'Eastern Time (US & Canada)')
  end

  describe '#future_assignment_summaries' do
    it 'finds and returns assignment summaries for the current student and section' do
      assignment_summaries = [double(DueDateList::AssignmentSummary)]
      due_date_list = double(DueDateList)
      expect(DueDateList).to receive(:new).with(@user, @section) { due_date_list }
      expect(due_date_list).to receive(:future_assignment_summaries).and_return(assignment_summaries)

      presenter = described_class.new(@user, @section)

      expect(presenter.future_assignment_summaries).to eq(assignment_summaries)
    end
  end

  describe '#incomplete_future_groups' do
    let(:user) { create(:student) }
    let(:section) { create(:section) }

    let(:due_date_1) { 3.days.from_now.to_date }
    let(:due_date_2) { 6.days.from_now.to_date }
    let(:summary_1) do
      instance_double(Assignment, due_date: due_date_1).tap do |assignment|
        assignment.extend(DueDateList::AssignmentSummary)
      end
    end
    let(:summary_2) do
      instance_double(Assignment, due_date: due_date_2).tap do |assignment|
        assignment.extend(DueDateList::AssignmentSummary)
      end
    end

    let(:group_1) do
      instance_double(DueDate::AssignmentGroup, complete?: true, :due_date= => nil)
    end
    let(:group_2) do
      instance_double(DueDate::AssignmentGroup, complete?: false, :due_date= => nil)
    end
    let(:group_3) do
      instance_double(DueDate::AssignmentGroup, complete?: false, :due_date= => nil)
    end

    let(:due_date_list) { instance_double(DueDateList) }
    let(:presenter) { described_class.new(user, section) }

    before do
      allow(DueDateList).to receive(:new).and_return(due_date_list)
      allow(due_date_list).to receive(:future_assignment_summaries)
        .and_return([summary_1, summary_2])
      allow(due_date_list).to receive(:assignment_groups)
        .with(summary_1)
        .and_return([group_1, group_2])
      allow(due_date_list).to receive(:assignment_groups)
        .with(summary_2)
        .and_return([group_3])
    end

    it 'creates a DueDateList instance, specifying the current user and section' do
      presenter.incomplete_future_groups

      expect(DueDateList).to have_received(:new).with(user, section)
    end

    it 'retrieves future assignment summaries from the DueDateList instance' do
      presenter.incomplete_future_groups

      expect(due_date_list).to have_received(:future_assignment_summaries)
    end

    it 'retrieves the assignment groups for each summary from the DueDateList ' \
       'instance' do
      presenter.incomplete_future_groups

      [summary_1, summary_2].each do |summary|
        expect(due_date_list).to have_received(:assignment_groups)
          .with(summary)
      end
    end

    it 'returns only assignment groups that are not completed' do
      expect(presenter.incomplete_future_groups).to eq(
        [group_2, group_3]
      )
    end

    it 'sets a due date property on each group from the due date of ' \
       'the summary' do
      presenter.incomplete_future_groups

      expect(group_2).to have_received(:due_date=).with(due_date_1)
      expect(group_3).to have_received(:due_date=).with(due_date_2)
    end
  end

  describe '#notifications_list' do
    let(:program) { create(:program) }
    let(:course) { create(:course, program: program) }
    let(:section) { create(:section, course: course) }

    let(:user) { create(:student) }

    let(:mock_list) { { foo: [:bar] } }

    let(:mock_notifications_presenter) do
      instance_double(
        NotificationsPresenter,
        notifications_and_announcements: mock_list
      )
    end

    let(:presenter) { described_class.new(user, section) }

    before do
      allow(NotificationsPresenter).to receive(:new).and_return(
        mock_notifications_presenter
      )
    end

    it 'instantiates a NotificationsPresenter, passing in user, section ' \
       'and the program associated with the section' do
      presenter.notifications_list

      expect(NotificationsPresenter).to have_received(:new).with(
        user, section, program
      )
    end

    it 'calls notifications_and_announcements on the instantiated ' \
       'NotificationsPresenter instance' do
      presenter.notifications_list

      expect(mock_notifications_presenter).to have_received(
        :notifications_and_announcements
      )
    end

    it 'returns the result of calling notifications_and_announcements on the ' \
       'instantiated NotificationsPresenter instance' do
      expect(presenter.notifications_list).to eq(mock_list)
    end
  end

  describe '#has_student_study_plans?' do
    let(:user) { create(:student) }
    let(:program) { create(:vol_program) }
    let(:course) { create(:course, program: program) }
    let(:section) { create(:section, course: course, time_zone: 'Eastern Time (US & Canada)') }
    let(:presenter) { described_class.new(user, section) }

    before do
      study_plan_concept = create(:study_plan_concept, program: program)
      create(:recommendation, study_plan_concept: study_plan_concept)
    end

    context 'when user has readings for the given program' do
      it 'returns true' do
        concept_recommendation = StudyPlanConceptRecommendation.first
        create(:user_reading, user: user, recommendation: concept_recommendation)

        expect(presenter).to have_student_study_plans
      end
    end

    context 'when user has readings for another program' do
      it 'returns false' do
        study_plan_concept = create(:study_plan_concept, program: create(:program))
        concept_recommendation = create(:recommendation, study_plan_concept: study_plan_concept)
        create(:user_reading, user: user, recommendation: concept_recommendation)

        expect(presenter).not_to have_student_study_plans
      end
    end

    context 'when user does not have readings for the given program' do
      it 'returns false' do
        expect(presenter).not_to have_student_study_plans
      end
    end
  end

  describe '#past_assignment_summaries' do
    it 'finds and returns assignment summaries for the current student and section' do
      assignment_summaries = [double(DueDateList::AssignmentSummary)]
      due_date_list = double(DueDateList)
      expect(DueDateList).to receive(:new).with(@user, @section) { due_date_list }
      expect(due_date_list).to receive(:past_assignment_summaries).and_return(assignment_summaries)

      presenter = described_class.new(@user, @section)

      expect(presenter.past_assignment_summaries).to eq(assignment_summaries)
    end
  end

  describe "#active_enrollment?" do
    it "returns true if current section is active for this user" do
      @enrollment = create(:active_enrollment, :section => @section, :user => @user)
      @presenter = described_class.new(@user, @section)

      expect(@presenter).to be_active_enrollment
    end

    it "returns false if section is closed" do
      @enrollment = create(:active_enrollment, :section => @section, :user => @user)
      @presenter = described_class.new(@user, @section)
      @section.course.start_date = 12.months.ago
      @section.course.end_date = 6.months.ago
      @section.course.allow_past_end_date = true
      expect(@presenter).not_to be_active_enrollment
    end

    it "returns false if student has dropped the section" do
      @enrollment = create(:dropped_enrollment, :section => @section, :user => @user)
      @presenter = described_class.new(@user, @section)
      expect(@presenter).not_to be_active_enrollment
    end

    it "returns false if the student was never enrolled in this section" do
      @presenter = described_class.new(@user, @section)
      expect(@presenter).not_to be_active_enrollment
    end
  end

  describe '#show_expanded?' do
    let(:due_date_list) { double('due_date_list') }
    let(:presenter) { described_class.new(@user, @section) }

    it 'gets the future due dates if summary due date is not less than today' do
      summary = double('summary', due_date: 1.day.from_now.to_date)

      expect(due_date_list).to receive(:first_incomplete_future_due_date?).with(summary)
      allow(presenter).to receive(:due_date_list).and_return(due_date_list)

      presenter.show_expanded?(summary)
    end

    it 'gets the past due dates if summary due date is less than today' do
      summary = double('summary', due_date: 1.day.ago.to_date)

      expect(due_date_list).to receive(:first_incomplete_past_due_date?).with(summary)
      allow(presenter).to receive(:due_date_list).and_return(due_date_list)

      presenter.show_expanded?(summary)
    end

    context 'when the due date is today' do
      it 'gets the past due dates if the summary date is past the due time' do
        summary = double('summary', due_date: Date.today)
        allow(@section).to receive(:date_in_past?).and_return(true)

        expect(due_date_list).to receive(:first_incomplete_past_due_date?).with(summary)
        allow(presenter).to receive(:due_date_list).and_return(due_date_list)

        presenter.show_expanded?(summary)

      end


      it 'gets the furture due dates if the summary date is not past the due time' do
        allow(@section).to receive(:date_in_past?).and_return(false)
        summary = double('summary', due_date: Date.today)

        expect(due_date_list).to receive(:first_incomplete_future_due_date?).with(summary)
        allow(presenter).to receive(:due_date_list).and_return(due_date_list)

        presenter.show_expanded?(summary)
      end
    end
  end

  describe '#assignments_details_url' do
    let(:summary) { double('summary', due_date: Date.today)}
    let(:presenter) { described_class.new(@user, @section) }

    it " returns the route to get the assignments by concepts for a due date" do
      expected_path = Rails.application.routes.url_helpers.course_assignments_by_due_date_path(course_id: @section.course_id,
                                                                                             section_id: @section.id,
                                                                                             due_date: summary.due_date)
      expect(presenter.assignments_details_url(summary)).to eql(expected_path)
    end
  end

  describe '#assignment_groups' do
    let(:summary) { double('summary', due_date: Date.today)}
    let(:presenter) { described_class.new(@user, @section) }
    let(:due_date_list) { double(DueDateList) }

    it "calls the next assingment finder method with today's date and count" do
      expect(due_date_list).to receive(:assignment_groups).with(summary)
      allow(presenter).to receive(:due_date_list).and_return(due_date_list)
      presenter.assignment_groups(summary)
    end
  end

  describe '#current_announcement_notifications' do
    it 'retrieves current announcements from section' do
      presenter = described_class.new(@user, @section)
      expect(@section).to receive(:current_announcement_notifications).with(@user)
      presenter.current_announcement_notifications
    end
  end

  describe '#assignment_days' do
    let(:section) { create(:section) }
    let(:student) { create(:student) }
    let(:current_due_day) { Time.now.in_time_zone(@section.time_zone).to_date }
    let(:presenter) { described_class.new(student, section) }
    let(:assignment_day_creator) do
      instance_double(
        described_class::AssignmentDayCreator,
        create: nil
      )
    end

    before do
      allow(described_class::AssignmentDayCreator).to receive(:new)
        .and_return(assignment_day_creator)
    end

    context 'when student is not enrolled in the section,' do
      it 'returns an empty array' do
        allow(presenter).to receive(:active_enrollment?).and_return(false)
        expect(presenter.assignment_days).to eq([])
      end
    end

    context 'when student is enrolled in the section,' do
      before do
        allow(presenter).to receive(:active_enrollment?).and_return(true)
        allow(presenter).to receive(:current_due_day?).and_return(current_due_day)
      end

      it 'creates assignemnt days with overdue assignments' do
        expect(assignment_day_creator).to receive(:create).with(current_due_day, pastdue = true)
        expect(presenter.assignment_days).to eq([])
      end

      context 'when there are due assignments with work to be done' do
        let(:due_date_1) { current_due_day + 2.days }
        let(:due_date_2) { current_due_day + 4.days }
        let(:assignment_1) { double(Assignment, due_date: due_date_1) }
        let(:assignment_2) { double(Assignment, due_date: due_date_2) }

        before do
          allow(presenter).to receive(:find_next_assignment_days).and_return([due_date_1, due_date_2])
        end

        it 'creates assignment days with available assignments that are current setting the first one to be expanded' do
          expect(assignment_day_creator).to receive(:create).with(due_date_1, pastdue = false, expanded = true)
          expect(assignment_day_creator).to receive(:create).with(due_date_2, pastdue = false, expanded = false)
          presenter.assignment_days
        end
      end

      context 'when days to show assignment due date is set in section' do
        let(:due_days_limit) { 2 }
        let(:due_date_1) { current_due_day + due_days_limit.days }
        let(:due_date_2) { current_due_day + due_days_limit.days + 2.days }
        let(:section_with_release_date) { create(:section, days_to_show_assignment_due_date: due_days_limit) }
        let(:section_without_release_date) { create(:section) }
        let(:presenter_with_release_date) { StudentDashboardPresenter.new(student, section_with_release_date) }
        let(:presenter_without_release_date) { StudentDashboardPresenter.new(student, section_without_release_date) }

        before do
          allow(presenter_with_release_date).to receive(:active_enrollment?).and_return(true)
          allow(presenter_with_release_date).to receive(:current_due_day?).and_return(current_due_day)
          allow(presenter_without_release_date).to receive(:active_enrollment?).and_return(true)
          allow(presenter_without_release_date).to receive(:current_due_day?).and_return(current_due_day)
          allow(StudentDashboardPresenter::AssignmentDayCreator).to receive(:new).and_call_original
        end

        it 'returns only due dates that are released to student when release date is set in section' do
          create(:assignment, due_date: due_date_1, section_id: section_with_release_date.id)
          create(:assignment, due_date: due_date_2, section_id: section_with_release_date.id)
          released_due_dates = presenter_with_release_date.serialize_assignment_days.map { |assignment_day| assignment_day[:due_date] }
          day_1 = released_due_dates.first

          expect(released_due_dates.count).to eq(1)
          expect(day_1).to eq(due_date_1)
        end

        it 'returns only due dates that are released to student when release date is not set in section' do
          create(:assignment, due_date: due_date_1, section_id: section_without_release_date.id)
          create(:assignment, due_date: due_date_2, section_id: section_without_release_date.id)
          released_due_dates = presenter_without_release_date.serialize_assignment_days.map { |assignment_day| assignment_day[:due_date] }
          day_1, day_2 = released_due_dates

          expect(released_due_dates.count).to eq(2)
          expect(day_1).to eq(due_date_1)
          expect(day_2).to eq(due_date_2)
        end

        context 'when user has individual assignments with custom due dates' do
          let(:default_due_date_1) { due_date_1 + 1.day }
          let(:default_due_date_2) { due_date_2 + 1.day }

          def create_individual_assignments(section)
            assignment_1 = create(
              :assignment,
              due_date: default_due_date_1,
              section_id: section.id
            )

            assignment_2 = create(
              :assignment,
              due_date: default_due_date_2,
              section_id: section.id
            )

            create(
              :individual_assignment,
              activity_id: assignment_1.assignable_id,
              due_date: due_date_1,
              section_id: section.id,
              user_id: student.id
            )

            create(
              :individual_assignment,
              activity_id: assignment_2.assignable_id,
              due_date: due_date_2,
              section_id: section.id,
              user_id: student.id
            )
          end

          it 'returns expected dates when release date is set in section' do
            create_individual_assignments(section_with_release_date)

            released_due_dates = presenter_with_release_date
                                 .serialize_assignment_days
                                 .map { |assignment_day| assignment_day[:due_date] }
            day_1 = released_due_dates.first

            expect(released_due_dates.count).to eq(1)
            expect(day_1).to eq(due_date_1)
          end

          it 'returns expected dates when release date is not set in section' do
            create_individual_assignments(section_without_release_date)

            released_due_dates = presenter_without_release_date
                                 .serialize_assignment_days
                                 .map { |assignment_day| assignment_day[:due_date] }
            day_1, day_2 = released_due_dates

            expect(released_due_dates.count).to eq(2)
            expect(day_1).to eq(due_date_1)
            expect(day_2).to eq(due_date_2)
          end
        end
      end
    end
  end

  describe '#serialize_assignment_days' do
    let(:assignment_day_1) { double(StudentDashboardPresenter::AssignmentDay, serialize: {}) }
    let(:assignment_day_2) { double(StudentDashboardPresenter::AssignmentDay, serialize: {}) }
    let(:assignment_list) { double(StudentDashboardPresenter::AssignmentDayList) }
    let(:presenter) { StudentDashboardPresenter.new(@user, @section) }

    it 'serializes assignment days' do
      allow(StudentDashboardPresenter::AssignmentDayList).to receive(:new).and_return(assignment_list)
      allow(assignment_list).to receive(:expand).and_return([assignment_day_1, assignment_day_2])
      expect(assignment_day_1).to receive(:serialize)
      expect(assignment_day_2).to receive(:serialize)
      presenter.serialize_assignment_days
    end
  end
end

describe StudentDashboardPresenter::AssignmentDayList do
  let(:student) { build_stubbed(:student) }
  let(:section) { instance_double(Section) }
  let(:assignment_day_1) do
    StudentDashboardPresenter::AssignmentDay.new(section, 'some date', [], student)
  end
  let(:assignment_day_2) do
    StudentDashboardPresenter::AssignmentDay.new(section, 'some date', [], student)
  end
  let(:overdue_day) do
    StudentDashboardPresenter::AssignmentDay.new(section, 'some date', [], student)
  end

  before  do
    allow(assignment_day_1).to receive(:overdue?).and_return(false)
    allow(assignment_day_2).to receive(:overdue?).and_return(false)
    allow(overdue_day).to receive(:overdue?).and_return(true)
    [assignment_day_1, assignment_day_2, overdue_day].each do |assignment_day|
      allow(assignment_day).to receive(:all_assignments_completed?).and_return(false)
    end
  end

  describe '#expand' do
    context 'when there is only one assignment day' do
      it 'is expanded when it has incomplete assignments' do
        results = StudentDashboardPresenter::AssignmentDayList.new([assignment_day_1]).expand
        expect(results.first.expanded).to be_truthy
      end

      it 'is also expanded when it has only completed assignments' do
        allow(assignment_day_1).to receive(:all_assignments_completed?).and_return(true)
        results = StudentDashboardPresenter::AssignmentDayList.new([assignment_day_1]).expand
        expect(results.first.expanded).to be_truthy
      end
    end

    context 'when there are two assignment days' do
      context 'when first assignment day has uncomplete assignments' do
        before do
          allow(assignment_day_2).to receive(:all_assignments_completed?).and_return(true)
          @results = StudentDashboardPresenter::AssignmentDayList.new([assignment_day_1, assignment_day_2]).expand
        end

        it 'first assignment day is expanded' do
          expect(@results.first.expanded).to be_truthy
        end

        it 'second assignment day is not expanded' do
          expect(@results.second.expanded).to be_falsey
        end
      end

      context 'when all assignments in first assignment day are complete' do
        before do
          allow(assignment_day_1).to receive(:all_assignments_completed?).and_return(true)
          @results = StudentDashboardPresenter::AssignmentDayList.new([assignment_day_1, assignment_day_2]).expand
        end

        it 'first assignment day is still expanded' do
          expect(@results.first.expanded).to be_truthy
        end

        it 'second assignment day is not expanded' do
          expect(@results.second.expanded).not_to be_truthy
        end
      end

      context 'when all assignments in both assignment days are complete' do
        before do
          allow(assignment_day_1).to receive(:all_assignments_completed?).and_return(true)
          allow(assignment_day_2).to receive(:all_assignments_completed?).and_return(true)
          @results = StudentDashboardPresenter::AssignmentDayList.new([assignment_day_1, assignment_day_2]).expand
        end

        it 'first assignment day is expanded' do
          expect(@results.first.expanded).to be_truthy
        end

        it 'second assignment day is not expanded' do
          expect(@results.second.expanded).not_to be_truthy
        end
      end
    end

    context 'when there are overdue assignments' do

      context 'when all assignments in both assignment days are complete' do
        before do
          allow(assignment_day_1).to receive(:all_assignments_completed?).and_return(true)
          allow(assignment_day_2).to receive(:all_assignments_completed?).and_return(true)
          @results = StudentDashboardPresenter::AssignmentDayList.new([overdue_day, assignment_day_1, assignment_day_2]).expand
        end

        it 'overdue assignments are not expanded' do
          expect(@results.first.expanded).not_to be_truthy
        end

        it 'only the first assignment day is expanded' do
          expect(@results[1].expanded).to be_truthy
          expect(@results[2].expanded).not_to be_truthy
        end
      end

      context 'when an assignment day has uncomplete assignments' do
        it 'overdue assignments are not expanded' do
          results = StudentDashboardPresenter::AssignmentDayList.new([overdue_day, assignment_day_1, assignment_day_2]).expand
          expect(results.first.expanded).not_to be_truthy
        end
      end
    end
  end
end

describe StudentDashboardPresenter::AssignmentDayCreator do
  describe '#create' do
    let(:category)  { create(:category) }
    let(:unit) { create(:unit, rank: 1) }
    let(:past_due_date) { 2.days.ago.to_date }
    let(:future_due_date) { 2.days.from_now.to_date }

    context "when creating pastdue days" do
      before do
        @user = create(:student)
        @course = create(:course)
        @section = create(:section, :course => @course)
        create(:enrollment, :section => @section, :user => @user)

        @lesson = create(:lesson, label: 'Lesson 1', unit: unit, rank: 2)
        @concept = create(:concept, lesson: @lesson, rank: 3)

        @uncompleted_activity_1 = create(:activity, :concept => @concept, :lesson => @lesson)
        @uncompleted_activity_2 = create(:activity, :concept => @concept, :lesson => @lesson)

        @unsubmitted_activity_1 = create(:activity, :concept => @concept, :lesson => @lesson)
        @unsubmitted_activity_2 = create(:activity, :concept => @concept, :lesson => @lesson)
        # activity was opened but not submitted.
        create(:attempt, user: @user, section: @section,
                         activity_id: @unsubmitted_activity_1.id,
                         status_code: AttemptStatus::CODE_OPENED)
        # second unsubmitted activity has no attempt, never opened by student

        @completed_activity_1 = create(:activity, :concept => @concept, :lesson => @lesson)
        @completed_activity_2 = create(:activity, :concept => @concept, :lesson => @lesson)
        # one attempt made
        create(:attempt, user: @user, section: @section,
                         activity_id: @completed_activity_1.id,
                         status_code: AttemptStatus::CODE_SUBMITTED)
        # all attempts used
        create(:attempt, user: @user, section: @section,
                         activity_id: @completed_activity_2.id,
                         status_code: AttemptStatus::CODE_COMPLETED)
      end

      context "when there are no pastdue items" do
        it "returns nil if there are no assignments" do
          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(Date.today, true)
          expect(assignment_day).to be_nil
        end

        it "should return nil if there are assignments in the future but none in the past" do
          create(:assignment, :due_date => future_due_date, :category => category,
                  :assignable => @uncompleted_activity_1, :section => @section)
          create(:assignment, :due_date => future_due_date, :category => category,
                  :assignable => @unsubmitted_activity_1, :section => @section)
          create(:assignment, :due_date => future_due_date, :category => category,
                  :assignable => @completed_activity_1, :section => @section)

          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(Date.today, true)
          expect(assignment_day).to be_nil
        end

        it "returns nil if there are assignments in the past but all are complete" do
          create(:assignment, :due_date => past_due_date, :category => category,
                  :assignable => @completed_activity_1, :section => @section)
          create(:assignment, :due_date => past_due_date, :category => category,
                  :assignable => @completed_activity_2, :section => @section)

          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(Date.today, true)
          expect(assignment_day).to be_nil
        end

        it "returns nil if there are incomplete past_due assignments in another section but not in the current one" do
          other_section = create(:section, :course => @course)
          create(:assignment, :due_date => past_due_date, :category => category,
                  :assignable => @uncompleted_activity_1, :section => other_section)


          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(Date.today, true)
          expect(assignment_day).to be_nil
        end
      end

      context "when there are past due activities" do
        before do
          create(:assignment, :due_date => past_due_date, :category => category,
                  :assignable => @unsubmitted_activity_1, :section => @section)
          @assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(Date.today, true)
        end

        it "returns an activity_day" do
          expect(@assignment_day).not_to be_nil
        end

        it "returns an activity_day marked as overdue" do
          expect(@assignment_day.overdue?).to be_truthy
        end

        it "returns an activity_day that has_assignment_banks" do
          expect(@assignment_day).not_to be_all_assignments_completed
        end

        it "returns an activity_day that has one bank goupr" do
          expect(@assignment_day.entries.size).to eq(1)
        end

        it "returns an activity_day with a bank group that contains all past due activities" do
          bank_group = @assignment_day.entries[0]
          expect(bank_group.total_assignments).to eq(1)
        end
      end

      context "when there are multiple pastdue activities for the same lesson/concept" do
        before do
          create(:assignment, :due_date => past_due_date, :category => category,
                  :assignable => @unsubmitted_activity_1, :section => @section)
          create(:assignment, :due_date => past_due_date, :category => category,
                  :assignable => @unsubmitted_activity_2, :section => @section)
          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(Date.today, true)
          @bank_groups = assignment_day.entries
          @banks = @bank_groups[0].entries
        end

        it "returns returns an assignment day with only one bank group" do
          expect(@bank_groups.size).to eq(1)
        end

        it "returns an assignment day with one activity bank" do
          expect(@banks.size).to eq(1)
        end

        it "has an activity bank with the correct lesson_label" do
          expect(@banks[0].lesson_label).to match @lesson.label
        end

        it "has an activity bank with the correct concept_name" do
          expect(@banks[0].concept_name).to match @concept.name
        end

        it "has an activity bank with the correct unit rank" do
          expect(@banks[0].unit_rank).to match unit.rank
        end

        it "has an activity bank with the correct lesson rank" do
          expect(@banks[0].lesson_rank).to match @lesson.rank
        end

        it "has an activity bank with the correct concept rank" do
          expect(@banks[0].concept_rank).to match @concept.rank
        end

        it "has an activity bank with the correct color" do
          expect(@banks[0].background_color).to match @concept.background_color
        end

        it "has an activity bank with the correct concept_unit_label" do
          expect(@banks[0].concept_unit_label).to match 'activity'
        end

        it "has an activity bank with the total number of pastdue activities in activity_count" do
          expect(@banks[0].activity_count).to eq(2)
        end

        it "has an activity bank with the total time for all pastdue activities in total_time" do
          expect(@banks[0].total_time).to eq(20)
        end

        it "has an activity bank that is not marked as an assessment" do
          expect(@banks[0].is_assessment).to be_falsey
        end
      end

      context 'when some pastdue activities are assigned individually,' do
        it 'includes only the activities assigned to all students or the ' \
           'current student' do
          # assigned to all students
          create(
            :assignment,
            assignable: @unsubmitted_activity_1,
            category: category,
            due_date: past_due_date,
            individually_assignable: false,
            section: @section
          )

          # individually assigned to current student
          create(
            :assignment,
            assignable: @unsubmitted_activity_2,
            category: category,
            due_date: past_due_date,
            individually_assignable: true,
            section: @section
          )
          IndividualAssignment.create!(
            activity_id: @unsubmitted_activity_2.id,
            section_id: @section.id,
            user_id: @user.id
          )

          # individually assigned, but not to current student
          create(
            :assignment,
            assignable: @uncompleted_activity_1,
            category: category,
            due_date: past_due_date,
            individually_assignable: true,
            section: @section
          )
          assignment_day = described_class.new(@user, @section).create(Date.today, true)
          bank_groups = assignment_day.entries
          expect(bank_groups[0].entries[0].activity_count).to eq(2)
        end
      end

      context 'when some activities are assigned with individual due dates,' do
        let(:uncompleted_activity_3) do
          create(:activity, concept: @concept, lesson: @lesson)
        end

        let(:uncompleted_activity_4) do
          create(:activity, concept: @concept, lesson: @lesson)
        end

        it 'includes only the activities assigned to all students, to the ' \
           'current student with no individual due date, or to the current ' \
           'student with an individual due date in the past' do
          # assigned to all students
          create(
            :assignment,
            assignable: @unsubmitted_activity_1,
            category: category,
            due_date: past_due_date,
            individually_assignable: false,
            section: @section
          )

          # individually assigned to current student, no custom due-date
          create(
            :assignment,
            assignable: @unsubmitted_activity_2,
            category: category,
            due_date: past_due_date,
            individually_assignable: true,
            section: @section
          )
          IndividualAssignment.create!(
            activity_id: @unsubmitted_activity_2.id,
            section_id: @section.id,
            user_id: @user.id
          )

          # individually assigned to current student, custom due-date in
          # the past
          create(
            :assignment,
            assignable: @uncompleted_activity_1,
            category: category,
            due_date: future_due_date,
            individually_assignable: true,
            section: @section
          )
          IndividualAssignment.create!(
            activity_id: @uncompleted_activity_1.id,
            due_date: past_due_date,
            section_id: @section.id,
            user_id: @user.id
          )

          # individually assigned to current student, custom due-date in
          # the future
          create(
            :assignment,
            assignable: @uncompleted_activity_2,
            category: category,
            due_date: past_due_date,
            individually_assignable: true,
            section: @section
          )
          IndividualAssignment.create!(
            activity_id: @uncompleted_activity_2.id,
            due_date: future_due_date,
            section_id: @section.id,
            user_id: @user.id
          )

          create(
            :assignment,
            assignable: uncompleted_activity_3,
            category: category,
            due_date: past_due_date,
            individually_assignable: true,
            section: @section
          )
          IndividualAssignment.create!(
            activity_id: uncompleted_activity_3.id,
            due_date: future_due_date,
            section_id: @section.id,
            user_id: @user.id
          )


          # individually assigned, but not to current student
          create(
            :assignment,
            assignable: uncompleted_activity_4,
            category: category,
            due_date: past_due_date,
            individually_assignable: true,
            section: @section
          )
          other_student = create(:student)
          IndividualAssignment.create!(
            activity_id: uncompleted_activity_4.id,
            due_date: past_due_date,
            section_id: @section.id,
            user_id: other_student.id
          )

          assignment_day = described_class.new(@user, @section).create(Date.today, true)
          bank_groups = assignment_day.entries
          expect(bank_groups[0].entries[0].activity_count).to eq(3)
        end
      end

      context "when there are multiple pastdue activities for different lesson/concepts" do

        before do
          create(:assignment, :due_date => past_due_date, :category => category,
                  :assignable => @unsubmitted_activity_1, :section => @section)
          other_concept = create(:concept, :lesson => @lesson)
          activity = create(:activity, :concept => other_concept, :lesson => @lesson)
          create(:assignment, :due_date => past_due_date, :category => category,
                  :assignable => activity, :section => @section)
          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(Date.today, true)
          @bank_groups = assignment_day.entries
          @banks = @bank_groups[0].entries
        end

        it "returns an assignment day with a single bank group" do
          expect(@bank_groups.size).to eq(1)
        end

        it "returns an assignment day with multiple activity banks" do
          expect(@banks.size).to eq(2)
        end
      end

      context "when there are pastdue assignments for multiple sections" do
        it "returns only pastdue assignment info for my current section" do
          other_section_1 = create(:section)
          other_section_2 = create(:section, :course => @section.course)
          create(:assignment, :due_date => past_due_date, :category => category,
                  :assignable => @unsubmitted_activity_1, :section => @section)
          create(:assignment, :due_date => past_due_date, :category => category,
                  :assignable => @unsubmitted_activity_1, :section => other_section_1)
          create(:assignment, :due_date => past_due_date, :category => category,
                  :assignable => @unsubmitted_activity_1, :section => other_section_2)
          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(Date.today, true)
          bank_groups = assignment_day.entries

          expect(bank_groups.size).to eq(1)
          expect(bank_groups[0].total_assignments).to eq(1)
        end

        it "returns nil if the only assignments are for other sections" do
          other_section_1 = create(:section)
          other_section_2 = create(:section, :course => @section.course)
          create(:assignment, :due_date => past_due_date, :category => category,
                  :assignable => @unsubmitted_activity_1, :section => other_section_1)
          create(:assignment, :due_date => past_due_date, :category => category,
                  :assignable => @unsubmitted_activity_1, :section => other_section_2)
          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(Date.today, true)
          expect(assignment_day).to be_nil
        end
      end

      context "when there are pastdue assessments" do
        before do
          @concept_quiz = create(:concept_for_quiz, :lesson => @lesson, :background_color => '#bbccdd')
          @concept_test = create(:concept_for_test, :lesson => @lesson, :background_color => '#ccddee')

          strand = double(TocEntry, :singular_label => 'quiz')
          allow(@lesson).to receive(:strand_for_toc_location).and_return(strand)

          @unsubmitted_activity_quiz_1 = create(:activity, :concept => @concept_quiz, :lesson => @lesson)
          @unsubmitted_activity_quiz_2 = create(:activity, :concept => @concept_quiz, :lesson => @lesson)
          @unsubmitted_activity_test = create(:activity, :concept => @concept_test, :lesson => @lesson)

          create(:assignment, :due_date => past_due_date, :category => category,
                  :assignable => @unsubmitted_activity_quiz_1, :section => @section,
                  :show_at => past_due_date)
          create(:assignment, :due_date => past_due_date, :category => category,
                  :assignable => @unsubmitted_activity_quiz_2, :section => @section,
                  :show_at => nil)
          create(:assignment, :due_date => past_due_date, :category => category,
                  :assignable => @unsubmitted_activity_test, :section => @section,
                  :show_at => future_due_date)
          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(Date.today, true)
          @bank_groups = assignment_day.entries
        end

        it "returns an assignment day with a bank group for each assessment" do
          expect(@bank_groups.size).to eq(3)
        end

        it "returns an assignment day with one bank per bank-group" do
          @bank_groups.each do |bank_group|
            banks = bank_group.entries
            expect(banks.size).to eq(1)
          end
        end

        it "has an activity bank that is not marked as an assessment" do
          @bank_groups.each do |bank_group|
            bank = bank_group.entries[0]
            expect(bank.is_assessment).to be_truthy
          end
        end

        it "each assessment bank has the correct lesson_label" do
          @bank_groups.each do |bank_group|
            bank = bank_group.entries[0]
            expect(bank.lesson_label).to match @lesson.label
          end
        end

        it "each assessment bank has the correct concept_name" do
          expect(@bank_groups[0].entries[0].concept_name).to eq(@concept_quiz.name)
          expect(@bank_groups[1].entries[0].concept_name).to eq(@concept_quiz.name)
          expect(@bank_groups[2].entries[0].concept_name).to eq(@concept_test.name)
        end

        it "each assessment bank has the correct color" do
          expect(@bank_groups[0].entries[0].background_color).to eq(@concept_quiz.background_color)
          expect(@bank_groups[1].entries[0].background_color).to eq(@concept_quiz.background_color)
          expect(@bank_groups[2].entries[0].background_color).to eq(@concept_test.background_color)
        end

        it "each assessment bank has the correct concept_unit_label" do
          expect(@bank_groups[0].entries[0].concept_unit_label).to match "quiz"
          expect(@bank_groups[1].entries[0].concept_unit_label).to match "quiz"
          expect(@bank_groups[2].entries[0].concept_unit_label).to match "test"
        end

        it "each assessment bank has the total 1 in t activity_count" do
          @bank_groups.each do |bank_group|
            bank = bank_group.entries[0]
            expect(bank.activity_count).to eq(1)
          end
        end

        it "each assessment bank has the total time for all pastdue activities in total_time" do
          @bank_groups.each do |bank_group|
            bank = bank_group.entries[0]
            expect(bank.total_time).to eq(10)
          end
        end

        it "each assessment bank has the correct assessment_id" do
          expect(@bank_groups[0].entries[0].assessment_id).to eq(@unsubmitted_activity_quiz_1.id)
          expect(@bank_groups[1].entries[0].assessment_id).to eq(@unsubmitted_activity_quiz_2.id)
          expect(@bank_groups[2].entries[0].assessment_id).to eq(@unsubmitted_activity_test.id)
        end

        it "each assessment bank released in the past is marked as released" do
           expect(@bank_groups[0].entries[0].is_released_assessment).to be_truthy
        end

        it "each assessment bank released in the future is marked as not released" do
          expect(@bank_groups[1].entries[0].is_released_assessment).to be_falsey
        end

        it "each assessment bank not yet released is marked as not released" do
           expect(@bank_groups[2].entries[0].is_released_assessment).to be_falsey
        end
      end

      context "when there are multiple pastdue activities and assessments" do
        before do
          @concept_quiz = create(:concept_for_quiz, :lesson => @lesson, :background_color => '#bbccdd')
          strand = double(:Strand, :singular_label => 'quiz')
          allow(@lesson).to receive(:strand_for_toc_location).and_return(strand)
          @unsubmitted_activity_quiz_1 = create(:activity, :concept => @concept_quiz, :lesson => @lesson)

          create(:assignment, :due_date => past_due_date, :category => category,
                  :assignable => @unsubmitted_activity_quiz_1, :section => @section,
                  :show_at => past_due_date)
          create(:assignment, :due_date => past_due_date, :category => category,
                  :assignable => @unsubmitted_activity_1, :section => @section)
          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(Date.today, true)
          @bank_groups = assignment_day.entries
        end

        it "returns 2 bank groups" do
          expect(@bank_groups.size).to eq(2)
        end

        it "returns an assignment day with multiple activity banks" do
          @bank_groups.each do |bank_group|
            banks = bank_group.entries
            expect(banks.size).to eq(1)
          end
        end
      end
    end

    context "when creating current assignment days" do

      before do
        @user = create(:student)
        @course = create(:course)
        @section = create(:section, :course => @course)
        create(:enrollment, :section => @section, :user => @user)
        @due_date = Date.tomorrow

        @lesson = create(:lesson, :label => "Lesson 1")
        @concept = create(:concept, :lesson => @lesson)

        @unopened_activity_1 = create(:activity, :concept => @concept, :lesson => @lesson)
        @unopened_activity_2 = create(:activity, :concept => @concept, :lesson => @lesson)

        @opened_activity_1 = create(:activity, :concept => @concept, :lesson => @lesson)
        @opened_activity_2 = create(:activity, :concept => @concept, :lesson => @lesson)
        create(:attempt_opened, :user => @user, :section => @section,
                                 :activity => @opened_activity_1)
        create(:attempt_opened, :user => @user, :section => @section,
                                 :activity => @opened_activity_2)

        @submitted_activity_1 = create(:activity, :concept => @concept, :lesson => @lesson)
        @submitted_activity_2 = create(:activity, :concept => @concept, :lesson => @lesson)
        create(:attempt_submitted, :user => @user, :section => @section,
                                    :activity => @submitted_activity_1)
        create(:attempt_submitted, :user => @user, :section => @section,
                                    :activity => @submitted_activity_2)

        @completed_activity_1 = create(:activity, :concept => @concept, :lesson => @lesson)
        @completed_activity_2 = create(:activity, :concept => @concept, :lesson => @lesson)
        create(:attempt_completed, :user => @user, :section => @section,
                                    :activity => @completed_activity_1)
        create(:attempt_completed, :user => @user, :section => @section,
                                    :activity => @completed_activity_2)

        @reset_activity_1 = create(:activity, :concept => @concept, :lesson => @lesson)
        @reset_activity_2 = create(:activity, :concept => @concept, :lesson => @lesson)
        create(:attempt_reset, :user => @user, :section => @section,
                                :activity => @reset_activity_1)
        create(:attempt_reset, :user => @user, :section => @section,
                                :activity => @reset_activity_2)
      end


      context "always" do
        before do
          @assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@due_date, false)
        end

        it "returns an activity_day" do
          expect(@assignment_day).not_to be_nil
        end

        it "returns an activity_day not marked as overdue" do
          expect(@assignment_day.overdue?).to be_falsey
        end
      end

      context "when there are no incomplete items" do
        context "when there are no assignments" do
          before do
            @assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@due_date, false)
          end

          it "returns an assignment day" do
            expect(@assignment_day).not_to be_nil
          end

          it "returns an assignment day with complete assignments" do
            expect(@assignment_day).to be_all_assignments_completed
          end

          it "returns an assignment day with no bank groups" do
            bank_groups = @assignment_day.entries
            expect(bank_groups).to be_empty
          end
        end

        context "when all assignments are complete" do
          before do
            create(:assignment, :due_date => @due_date, :category => category,
                    :assignable => @completed_activity_1, :section => @section)
            create(:assignment, :due_date => @due_date, :category => category,
                    :assignable => @completed_activity_2, :section => @section)

            @assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@due_date, false)
          end

          it "returns an assignment day" do
            expect(@assignment_day).not_to be_nil
          end

          it "returns an assignment day with complete assignments" do
            expect(@assignment_day).to be_all_assignments_completed
          end

          it "returns an assignment day with no bank groups" do
            bank_groups = @assignment_day.entries
            expect(bank_groups).to be_empty
          end
        end

        it "returns a day with complete assignments if there are incomplete assignments in another section but not in the current one" do
          other_section = create(:section, course: @course)
          create(
            :assignment,
            assignable: @unopened_activity_1,
            category: category,
            due_date: @due_date,
            section: other_section
          )

          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@due_date, false)
          expect(assignment_day).not_to be_nil
          expect(assignment_day).to be_all_assignments_completed
        end

        it "returns a day with complete assignments even if surrounding days have incomplete assigned work" do
          create(:assignment, :due_date => @due_date + 1, :category => category,
                  :assignable => @unopened_activity_1, :section => @section)
          create(:assignment, :due_date => @due_date - 1, :category => category,
                  :assignable => @unopened_activity_2, :section => @section)

          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@due_date, false)
          expect(assignment_day).not_to be_nil
          expect(assignment_day).to be_all_assignments_completed
        end
      end

      context 'when some activities are assigned individually,' do
        it 'includes only the activities assigned to all students or the ' \
           'current student' do
          # assigned to all students
          create(
            :assignment,
            assignable: @unopened_activity_1,
            category: category,
            due_date: past_due_date,
            individually_assignable: false,
            section: @section
          )

          # individually assigned to current student
          create(
            :assignment,
            assignable: @unopened_activity_2,
            category: category,
            due_date: past_due_date,
            individually_assignable: true,
            section: @section
          )
          IndividualAssignment.create!(
            activity_id: @unopened_activity_2.id,
            section_id: @section.id,
            user_id: @user.id
          )

          # individually assigned, but not to current student
          create(
            :assignment,
            assignable: @opened_activity_1,
            category: category,
            due_date: past_due_date,
            individually_assignable: true,
            section: @section
          )
          assignment_day = described_class.new(@user, @section).create(past_due_date, false)
          bank_groups = assignment_day.entries
          expect(bank_groups[0].entries[0].activity_count).to eq(2)
        end
      end

      context 'when some activities are assigned with individual due dates,' do
        let(:unopened_activity_3) do
          create(:activity, concept: @concept, lesson: @lesson)
        end

        let(:target_due_date) { Date.tomorrow }

        it 'includes only the activities assigned to all students, to the ' \
           'current student with no individual due date, or to the current ' \
           'student with an individual due date matching the specified date' do
          # assigned to all students
          create(
            :assignment,
            assignable: @unopened_activity_1,
            category: category,
            due_date: target_due_date,
            individually_assignable: false,
            section: @section
          )

          # individually assigned to current student, no custom due-date
          create(
            :assignment,
            assignable: @unopened_activity_2,
            category: category,
            due_date: target_due_date,
            individually_assignable: true,
            section: @section
          )
          IndividualAssignment.create!(
            activity_id: @unopened_activity_2.id,
            section_id: @section.id,
            user_id: @user.id
          )

          # individually assigned to current student, custom due-date
          # matching specified date
          create(
            :assignment,
            assignable: @opened_activity_1,
            category: category,
            due_date: future_due_date,
            individually_assignable: true,
            section: @section
          )
          IndividualAssignment.create!(
            activity_id: @opened_activity_1.id,
            due_date: target_due_date,
            section_id: @section.id,
            user_id: @user.id
          )

          # individually assigned to current student, custom due-date
          # different from specified date
          create(
            :assignment,
            assignable: @opened_activity_2,
            category: category,
            due_date: future_due_date,
            individually_assignable: true,
            section: @section
          )
          IndividualAssignment.create!(
            activity_id: @opened_activity_2.id,
            due_date: future_due_date,
            section_id: @section.id,
            user_id: @user.id
          )

          # individually assigned, but not to current student
          create(
            :assignment,
            assignable: unopened_activity_3,
            category: category,
            due_date: past_due_date,
            individually_assignable: true,
            section: @section
          )

          other_student = create(:student)
          IndividualAssignment.create!(
            activity_id: unopened_activity_3.id,
            due_date: past_due_date,
            section_id: @section.id,
            user_id: other_student.id
          )

          assignment_day = described_class.new(@user, @section).create(target_due_date, false)
          bank_groups = assignment_day.entries
          expect(bank_groups[0].entries[0].activity_count).to eq(3)
        end
      end

      context "when there are multiple incopmlete activities from the same concept" do

        before do
          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @unopened_activity_1, :section => @section)
          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @unopened_activity_2, :section => @section)
          @assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@due_date, false)
          @bank_groups = @assignment_day.entries
          @banks = @bank_groups[0].entries
        end

        it "returns an activity_day that has uncomplete assignments" do
          expect(@assignment_day).not_to be_all_assignments_completed
        end

        it "returns an assignment day with only one bank group" do
          expect(@bank_groups.size).to eq(1)
        end

        it "returns an assignment day with one activity bank" do
          expect(@banks.size).to eq(1)
        end

        it "has an activity bank with the correct lesson_label" do
          expect(@banks[0].lesson_label).to match @lesson.label
        end

        it "has an activity bank with the correct concept_name" do
          expect(@banks[0].concept_name).to match @concept.name
        end

        it "has an activity bank with the correct color" do
          expect(@banks[0].background_color).to match @concept.background_color
        end

        it "has an activity bank with the correct concept_unit_label" do
          expect(@banks[0].concept_unit_label).to match 'activity'
        end

        it "has an activity bank with the total number of pastdue activities in activity_count" do
          expect(@banks[0].activity_count).to eq(2)
        end

        it "has an activity bank with the total time for all pastdue activities in total_time" do
          expect(@banks[0].total_time).to eq(20)
        end

        it "has an activity bank that is not marked as an assessment" do
          expect(@banks[0].is_assessment).to be_falsey
        end
      end

      context "when there are different types of uncompleted activities" do
        it "returns an activity day that has uncompleted assignments for activities that have only been opened" do
          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @opened_activity_1, :section => @section)
          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @opened_activity_2, :section => @section)
          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@due_date, false)
          expect(assignment_day).not_to be_all_assignments_completed
        end

        it "returns an activity day that has completed assignments for activities that have been submitted" do
          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @submitted_activity_1, :section => @section)
          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @submitted_activity_2, :section => @section)
          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@due_date, false)
          expect(assignment_day).to be_all_assignments_completed
        end

        it "returns an activity day that has activities that have been completed" do
          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @completed_activity_1, :section => @section)
          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @completed_activity_2, :section => @section)
          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@due_date, false)
          expect(assignment_day).to be_all_assignments_completed
        end

        it "returns an activity day that has uncomplete assignments for activities that have been reset" do
          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @reset_activity_1, :section => @section)
          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @reset_activity_2, :section => @section)
          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@due_date, false)
          expect(assignment_day).not_to be_all_assignments_completed
        end
      end

      context "when there are multiple activities for different lesson/concepts" do
        before do
          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @unopened_activity_1, :section => @section)
          other_concept = create(:concept, :lesson => @lesson)
          activity = create(:activity, :concept => other_concept, :lesson => @lesson)
          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => activity, :section => @section)
          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@due_date, false)
          @bank_groups = assignment_day.entries
          @banks = @bank_groups[0].entries
        end

        it "returns an assignment day with 1 bank group" do
          expect(@bank_groups.size).to eq(1)
        end

        it "returns an assignment day with multiple activity banks" do
          expect(@banks.size).to eq(2)
        end
      end

      context "when other students have complete the assignments but I have not " do
        it "should return the total number of assignmnets I still need to do" do
          user_in_my_section = create(:student)
          create(:enrollment, :section => @section, :user => user_in_my_section)

          user_in_other_section = create(:student)
          other_section = create(:section)
          create(:enrollment, :section => other_section, :user => user_in_other_section)

          activity = create(:activity, :concept => @concept, :lesson => @lesson)
          create(:attempt_completed, :user => user_in_my_section, :section => @section,
                                      :activity => activity)
          create(:attempt_completed, :user => user_in_other_section, :section => other_section,
                                      :activity => activity)

          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => activity, :section => @section)

          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@due_date, false)
          bank_groups = assignment_day.entries

          expect(bank_groups.size).to eq(1)
          bank_groups[0].total_assignments == 1
        end
      end

      context "when there is one activity in a bank and i have a reset attempt for that activity" do
        it "includes that activity in the count of activities I need to complete" do
          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @reset_activity_1, :section => @section)

          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@due_date, false)
          bank_groups = assignment_day.entries
          expect(bank_groups).not_to be_empty
          bank_groups.first.total_assignments == 1
        end
      end

      context "when there is one activity in a bank and i have both a completed and a reset attempt for that activity" do
        it "does not include that activity in the count of activities I need to complete" do
          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @reset_activity_1, :section => @section)
          create(:attempt_completed, :user => @user, :section => @section,
                                      :activity => @reset_activity_1)

          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@due_date, false)
          bank_groups = assignment_day.entries
          expect(bank_groups).to be_empty
        end
      end

      context "when there is one activity in a bank and I have a completed attempt for that activity in another section" do
        it "includes that activity in the count of activities I need to complete" do
          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @unopened_activity_1, :section => @section)
          create(:attempt_completed, :user => @user, :section => create(:section),
                                      :activity => @unopened_activity_1)

          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@due_date, false)
          bank_groups = assignment_day.entries
          expect(bank_groups).not_to be_empty
          bank_groups.first.total_assignments == 1
        end
      end

      context "when there are assessments" do

        before do
          @concept_quiz = create(:concept_for_quiz, :lesson => @lesson, :background_color => '#bbccdd')
          @concept_test = create(:concept_for_test, :lesson => @lesson, :background_color => '#ccddee')

          strand = double(:Strand, :singular_label => 'quiz')
          allow(@lesson).to receive(:strand_for_toc_location).and_return(strand)

          @unopened_activity_quiz_1 = create(:activity, :concept => @concept_quiz, :lesson => @lesson)
          @unopened_activity_quiz_2 = create(:activity, :concept => @concept_quiz, :lesson => @lesson)
          @unopened_activity_test = create(:activity, :concept => @concept_test, :lesson => @lesson)

          @opened_activity_quiz_1 = create(:activity, :concept => @concept_quiz, :lesson => @lesson)
          create(:attempt_opened, :user => @user, :section => @section,
                                   :activity => @opened_activity_quiz_1)

          @submitted_activity_quiz_1 = create(:activity, :concept => @concept_quiz, :lesson => @lesson)
          create(:attempt_submitted, :user => @user, :section => @section,
                                   :activity => @submitted_activity_quiz_1)

          @completed_activity_quiz_1 = create(:activity, :concept => @concept_quiz, :lesson => @lesson)
          create(:attempt_completed, :user => @user, :section => @section,
                                   :activity => @completed_activity_quiz_1)

          @reset_activity_quiz_1 = create(:activity, :concept => @concept_quiz, :lesson => @lesson)
          create(:attempt_reset, :user => @user, :section => @section,
                                   :activity => @reset_activity_quiz_1)

          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @unopened_activity_quiz_1, :section => @section,
                  :show_at => past_due_date)
          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @unopened_activity_quiz_2, :section => @section,
                  :show_at => nil)
          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @unopened_activity_test, :section => @section,
                  :show_at => future_due_date)
          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@due_date, false)
          @bank_groups = assignment_day.entries
        end

        it "returns an assignment day with an bank group for each assessment" do
          expect(@bank_groups.size).to eq(3)
        end

        it "returns an assignment day with one assessment bank per bank group" do
          @bank_groups.each do |bank_group|
            banks = bank_group.entries
            expect(banks.size).to eq(1)
          end
        end

        it "returns an assignment day with the banks marked as assessments" do
          @bank_groups.each do |bank_group|
            banks = bank_group.entries
            expect(banks[0].is_assessment).to be_truthy
          end
        end

        it "returnas an assignment day where bank has the correct lesson_label" do
          @bank_groups.each do |bank_group|
            bank_group.each do |bank|
              expect(bank.lesson_label).to match @lesson.label
            end
          end
        end

        it "each assessment bank has the correct concept_name" do
          expect(@bank_groups[0].entries[0].concept_name).to match @concept_quiz.name
          expect(@bank_groups[1].entries[0].concept_name).to match @concept_quiz.name
          expect(@bank_groups[2].entries[0].concept_name).to match @concept_test.name
        end

        it "each assessment bank has the correct color" do
          expect(@bank_groups[0].entries[0].background_color).to match @concept_quiz.background_color
          expect(@bank_groups[1].entries[0].background_color).to match @concept_quiz.background_color
          expect(@bank_groups[2].entries[0].background_color).to match @concept_test.background_color
        end

        it "each assessment bank has the correct concept_unit_label" do
          expect(@bank_groups[0].entries[0].concept_unit_label).to match "quiz"
          expect(@bank_groups[1].entries[0].concept_unit_label).to match "quiz"
          expect(@bank_groups[2].entries[0].concept_unit_label).to match "test"
        end

        it "each assessment bank has the total 1 in t activity_count" do
          @bank_groups.each do |bank_group|
            banks = bank_group.entries
            banks.each{ |bank| expect(bank.activity_count).to eq(1) }
          end
        end

        it "each assessment bank has the total time for all pastdue activities in total_time" do
          @bank_groups.each do |bank_group|
            banks = bank_group.entries
            banks.each{ |bank| expect(bank.total_time).to eq(10) }
          end
        end

        it "each assessment bank has the correct assessment_id" do
          expect(@bank_groups[0].entries[0].assessment_id).to eq(@unopened_activity_quiz_1.id)
          expect(@bank_groups[1].entries[0].assessment_id).to eq(@unopened_activity_quiz_2.id)
          expect(@bank_groups[2].entries[0].assessment_id).to eq(@unopened_activity_test.id)
        end

        it "each assessment bank released in the past is marked as released" do
          expect(@bank_groups[0].entries[0].is_released_assessment).to be_truthy
        end

        it "each assessment bank released in the future is marked as not released" do
          expect(@bank_groups[1].entries[0].is_released_assessment).to be_falsey
        end

        it "each assessment bank not yet released is marked as not released" do
          expect(@bank_groups[2].entries[0].is_released_assessment).to be_falsey
        end

      context 'when some assessments are assigned individually,' do
        it 'includes only the assessments assigned to all students or the ' \
           'current student' do
          # assigned to all students
          Assignment.find_by(
            assignable_id: @unopened_activity_quiz_1
          ).update!(individually_assignable: false)

          # individually assigned to current student
          Assignment.find_by(
            assignable_id: @unopened_activity_quiz_2
          ).update!(individually_assignable: true)

          IndividualAssignment.create!(
            activity_id: @unopened_activity_quiz_2.id,
            section_id: @section.id,
            user_id: @user.id
          )

          # individually assigned, but not to current student
          Assignment.find_by(
            assignable_id: @unopened_activity_test
          ).update!(individually_assignable: true)

          assignment_day = described_class.new(@user, @section).create(@due_date, false)
          bank_groups = assignment_day.entries
          expect(bank_groups.size).to eq(2)
        end
      end

      context 'when some assessments are assigned with individual due dates,' do
        let(:unopened_activity_quiz_3) do
          create(:activity, concept: @concept_quiz, lesson: @lesson)
        end

        let(:unopened_activity_quiz_4) do
          create(:activity, concept: @concept_quiz, lesson: @lesson)
        end

        it 'includes only the assessments assigned to all students or the ' \
           'current student with no individual due date, or to the current' \
           'student with an individual due date matching the specified date' do
          # assigned to all students
          Assignment.find_by(
            assignable_id: @unopened_activity_quiz_1
          ).update!(individually_assignable: false)

          # individually assigned to current student with no individual due date
          Assignment.find_by(
            assignable_id: @unopened_activity_quiz_2
          ).update!(individually_assignable: true)

          IndividualAssignment.create!(
            activity_id: @unopened_activity_quiz_2.id,
            section_id: @section.id,
            user_id: @user.id
          )

          # individually assigned to current student, custom due-date
          # matching specified date
          create(
            :assignment,
            due_date: past_due_date,
            category: category,
            assignable: unopened_activity_quiz_3,
            section: @section,
            show_at: past_due_date
          )

          IndividualAssignment.create!(
            activity_id: unopened_activity_quiz_3.id,
            due_date: @due_date,
            section_id: @section.id,
            user_id: @user.id
          )

          # individually assigned to current student, custom due-date
          # different from specified date
          create(
            :assignment,
            due_date: past_due_date,
            category: category,
            assignable: unopened_activity_quiz_4,
            section: @section,
            show_at: past_due_date
          )

          IndividualAssignment.create!(
            activity_id: unopened_activity_quiz_4.id,
            due_date: future_due_date,
            section_id: @section.id,
            user_id: @user.id
          )

          # individually assigned, but not to current student
          Assignment.find_by(
            assignable_id: @unopened_activity_test
          ).update!(individually_assignable: true)

          other_student = create(:student)
          IndividualAssignment.create!(
            activity_id: @unopened_activity_test.id,
            due_date: @due_date,
            section_id: @section.id,
            user_id: other_student.id
          )

          assignment_day = described_class.new(@user, @section).create(@due_date, false)
          bank_groups = assignment_day.entries
          expect(bank_groups.size).to eq(3)
        end
      end

        context "with different statuses" do
          before do
            @other_due_date = @due_date + 1
          end

          it "returns an activity day that has uncomplete assignments for activities that have only been opened" do
            create(:assignment, :due_date => @other_due_date, :category => category,
                    :assignable => @opened_activity_quiz_1, :section => @section)
            assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@other_due_date, false)

            expect(assignment_day).not_to be_all_assignments_completed
          end

          it "returns an activity day that has completed assignments for activities that have been submitted" do
            create(:assignment, :due_date => @other_due_date, :category => category,
                    :assignable => @submitted_activity_quiz_1, :section => @section)
            assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@other_due_date, false)

            expect(assignment_day).to be_all_assignments_completed
          end

          it "returns an activity day that has completed activities" do
            create(:assignment, :due_date => @other_due_date, :category => category,
                    :assignable => @completed_activity_quiz_1, :section => @section)
            assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@other_due_date, false)

            expect(assignment_day).to be_all_assignments_completed
          end

          it "returns an activity day that has uncomplete assignments for activities that have been reset" do
            create(:assignment, :due_date => @other_due_date, :category => category,
                    :assignable => @reset_activity_quiz_1, :section => @section)
            assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@other_due_date, false)

            expect(assignment_day).not_to be_all_assignments_completed
          end

        end
      end

      context "when there are both activities and assessments" do

        before do
          @concept_quiz = create(:concept_for_quiz, :lesson => @lesson, :background_color => '#bbccdd')
          strand = double(:Strand, :singular_label => 'quiz')
          allow(@lesson).to receive(:strand_for_toc_location).and_return(strand)
          @unopened_activity_quiz_1 = create(:activity, :concept => @concept_quiz, :lesson => @lesson)

          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @unopened_activity_quiz_1, :section => @section,
                  :show_at => past_due_date)
          create(:assignment, :due_date => @due_date, :category => category,
                  :assignable => @unopened_activity_1, :section => @section)
          assignment_day = StudentDashboardPresenter::AssignmentDayCreator.new(@user, @section).create(@due_date, false)
          @bank_groups = assignment_day.entries
        end

        it "returns an assessment day with 2 bank groups one for assessment and one for activity banks" do
          expect(@bank_groups.size).to eq(2)
          expect(@bank_groups.one? { |bg| bg.entries[0].is_assessment }).to be_truthy
          expect(@bank_groups.one? { |bg| !bg.entries[0].is_assessment }).to be_truthy
        end

      end
    end
  end
end

describe StudentDashboardPresenter::AssignmentDay do
  let(:bank_class) { StudentDashboardPresenter::AssignmentBank }
  let(:course) { create(:course) }
  let(:student) { build_stubbed(:student) }
  let(:due_date) { Date.new(2012, 6, 1) }
  let(:custom_time) { Time.parse('11:30 PM') }

  let(:section) do
    create(:section, course: course, time_zone: 'Eastern Time (US & Canada)')
  end

  let(:bank_stubs) do
    {
      activity_count: 1,
      activity_count_text: '1 activity',
      assessment_id: 1,
      background_color: 'color',
      concept_name: 'concept',
      concept_rank: 0,
      concept_unit_label: 'activity',
      is_released_assessment: true,
      lesson_label: 'lesson',
      lesson_rank: 0,
      total_time: 10,
      unit_rank: 0,
      assignment_set_rank: 0,
      activity_concept_rank: 0,
      activity_toc_location_rank: 0
    }
  end

  let(:banks) do
    [
      instance_double(
        bank_class,
        bank_stubs.merge(is_assessment: false, custom_due_time: nil)
      ),
      instance_double(
        bank_class,
        bank_stubs.merge(is_assessment: true, custom_due_time: custom_time)
      ),
      instance_double(
        bank_class,
        bank_stubs.merge(is_assessment: false, custom_due_time: nil)
      ),
      instance_double(
        bank_class,
        bank_stubs.merge(is_assessment: true, custom_due_time: custom_time)
      ),
      instance_double(
        bank_class,
        bank_stubs.merge(is_assessment: false, custom_due_time: nil)
      )
    ]
  end

  let(:assignment_day) { described_class.new(section, due_date, banks, student) }

  describe '#label' do
    it 'returns the formated due date when representing for a day' do
      expect(assignment_day.label).to match 'Friday, June 1st'
    end

    it "returns the string 'overdue' when it was initialized with the string 'overdue'" do
      assignment_day = described_class.new(section, 'overdue', [], student)

      expect(assignment_day.label).to match 'Overdue'
    end
  end

  describe '#all_assignments_completed?' do
    it 'returns false if there are assignment banks' do
      expect(assignment_day.all_assignments_completed?).to be_falsey
    end

    it 'returns true if there are no assignment banks' do
      assignment_day = described_class.new(section, due_date, [], student)

      expect(assignment_day.all_assignments_completed?).to be_truthy
    end
  end

  describe '#each' do
    context 'with only activity banks,' do
      it 'yields the activity banks as one group' do
        banks = [
          instance_double(
            bank_class,
            bank_stubs.merge(is_assessment: false, custom_due_time: nil)
          ),
          instance_double(
            bank_class,
            bank_stubs.merge(is_assessment: false, custom_due_time: nil)
          ),
          instance_double(
            bank_class,
            bank_stubs.merge(is_assessment: false, custom_due_time: nil)
          )
        ]
        assignment_day = described_class.new(section, due_date, banks, student)

        expect(
          assignment_day.map { |bank_group| bank_group.entries.size }
        ).to eq([3])
      end
    end

    context 'with only assessment banks' do
      it 'yields each bank in a seperate group' do
        banks = [
          instance_double(
            bank_class,
            bank_stubs.merge(is_assessment: true, custom_due_time: custom_time)
          ),
          instance_double(
            bank_class,
            bank_stubs.merge(is_assessment: true, custom_due_time: custom_time)
          ),
          instance_double(
            bank_class,
            bank_stubs.merge(is_assessment: true, custom_due_time: custom_time)
          ),
          instance_double(
            bank_class,
            bank_stubs.merge(is_assessment: true, custom_due_time: custom_time)
          )
        ]
        assignment_day = described_class.new(section, due_date, banks, student)

        expect(
          assignment_day.map { |bank_group| bank_group.entries.size }
        ).to eq([1, 1, 1, 1])
      end
    end

    context 'with a mix of activity and assessment banks,' do
      let(:banks) do
        [
          instance_double(
            bank_class,
            bank_stubs.merge(is_assessment: true, custom_due_time: custom_time)
          ),
          instance_double(
            bank_class,
            bank_stubs.merge(is_assessment: false, custom_due_time: nil)
          ),
          instance_double(
            bank_class,
            bank_stubs.merge(is_assessment: true, custom_due_time: custom_time)
          ),
          instance_double(
            bank_class,
            bank_stubs.merge(is_assessment: false, custom_due_time: nil)
          ),
          instance_double(
            bank_class,
            bank_stubs.merge(is_assessment: true, custom_due_time: custom_time)
          ),
          instance_double(
            bank_class,
            bank_stubs.merge(is_assessment: true, custom_due_time: custom_time)
          ),
          instance_double(
            bank_class,
            bank_stubs.merge(is_assessment: false, custom_due_time: nil)
          )
        ]
      end

      it 'yields the activity banks all together as the first group' do
        assignment_day.each do |bank_group|
          expect(bank_group.entries.length).to eq(3)
          bank_group.each do |bank|
            expect(bank.is_assessment).to be_falsey
          end
          break
        end
      end

      it 'yields the the correct number of groups' do
        count = 0
        assignment_day.each do |bank_group|
          count += 1
        end
        expect(count).to eq(5)
      end
    end
  end

  describe '#overdue?' do
    it 'returns true if the day was initialized with overdue' do
      assignment_day = described_class.new(section, 'overdue', [], student, student)

      expect(assignment_day).to be_overdue
    end

    it 'returns false if the day was initialized with a duedate' do
      assignment_day = described_class.new(section, Date.tomorrow, [], student, student)

      expect(assignment_day).not_to be_overdue
    end
  end

  describe '#total_assignments' do
    it 'returns the total count of assignments for the entire day' do
      banks = [
        instance_double(
          bank_class,
          bank_stubs.merge(
            activity_count: 10,
            is_assessment: false,
            custom_due_time: nil
          )
        ),
        instance_double(
          bank_class,
          bank_stubs.merge(
            activity_count: 5,
            is_assessment: false,
            custom_due_time: nil
          )
        ),
        instance_double(
          bank_class,
          bank_stubs.merge(
            activity_count: 1,
            is_assessment: true,
            custom_due_time: custom_time
          )
        ),
        instance_double(
          bank_class,
          bank_stubs.merge(
            activity_count: 1,
            is_assessment: true,
            custom_due_time: custom_time
          )
        )
      ]
      assignment_day = described_class.new(section, Date.tomorrow, banks, student)

      expect(assignment_day.total_assignments).to eq(17)
    end

    it 'returns 1 if there is only 1 assignment for the entire day' do
      banks = [
        instance_double(
          bank_class,
          bank_stubs.merge(
            activity_count: 1,
            is_assessment: false,
            custom_due_time: nil
          )
        )
      ]
      assignment_day = described_class.new(section, Date.tomorrow, banks, student)

      expect(assignment_day.total_assignments).to eq(1)
    end

    it 'returns 0 if there are no assignments for the entire day' do
      banks = []
      assignment_day = described_class.new(section, Date.tomorrow, banks, student)

      expect(assignment_day.total_assignments).to eq(0)
    end
  end

  describe '#total_assignments_label' do
    it 'is plural if there are 2 or more assignments for the entire day' do
      banks = [
        instance_double(
          bank_class,
          bank_stubs.merge(
            activity_count: 10,
            is_assessment: false,
            custom_due_time: nil
          )
        ),
        instance_double(
          bank_class,
          bank_stubs.merge(
            activity_count: 5,
            is_assessment: false,
            custom_due_time: nil
          )
        ),
        instance_double(
          bank_class,
          bank_stubs.merge(
            activity_count: 1,
            is_assessment: true,
            custom_due_time: custom_time
          )
        ),
        instance_double(
          bank_class,
          bank_stubs.merge(
            activity_count: 1,
            is_assessment: true,
            custom_due_time: custom_time
          )
        )
      ]
      assignment_day = described_class.new(section, Date.tomorrow, banks, student)

      expect(assignment_day.total_assignments_label).to match 'assignments'
    end

    it 'is singular if there is only 1 assignment for the entire day' do
      banks = [
        instance_double(
          bank_class,
          bank_stubs.merge(
            activity_count: 1,
            is_assessment: false,
            custom_due_time: nil
          )
        )
      ]
      assignment_day = described_class.new(section, Date.tomorrow, banks, student)

      expect(assignment_day.total_assignments_label).to eq('assignment')
    end

    it 'is plural if there are no assignments for the entire day' do
      banks = []
      assignment_day = described_class.new(section, Date.tomorrow, banks, student)

      expect(assignment_day.total_assignments_label).to eq('assignments')
    end
  end

  describe '#serialize' do
    let(:serialized_group) { { some_key: :some_value } }

    before do
      assignment_day.each do |bank_group|
        allow(bank_group).to receive(:serialize).and_return(serialized_group)
      end
    end

    it 'returns a hash version of the assignment day' do
      expect(assignment_day.serialize).to include(
        course_show_estimated_times: section.course_show_estimated_times?,
        due_date: assignment_day.due_date,
        expanded: assignment_day.expanded,
        label: assignment_day.label,
        overdue: assignment_day.overdue?,
        total_assignments: assignment_day.total_assignments,
        total_assignments_label: assignment_day.total_assignments_label
      )
    end

    it 'serializes assignment groups' do
      assignment_day.serialize

      assignment_day.each do |bank_group|
        expect(bank_group).to have_received(:serialize)
      end
    end

    it 'includes an assignment_groups key with an array of serialized groups' do
      expect(assignment_day.serialize[:assignment_groups]).to contain_exactly(
        serialized_group, serialized_group, serialized_group
      )
    end

    it 'sets all_assignments_completed to false when the assignment day ' \
       'has bank groups' do
      expect(assignment_day.serialize[:all_assignments_completed]).to be_falsey
    end
  end
end

describe StudentDashboardPresenter::AssignmentBankGroup do
  include ApplicationHelper
  include DateTimeHelper
  include Rails.application.routes.url_helpers

  let(:student) { build_stubbed(:student) }
  let(:section) { build_stubbed(:section) }
  let(:bank_stubs) do
    {
      activity_count: 1,
      activity_count_text: '1 activity',
      assessment_id: 1,
      background_color: 'color',
      concept_name: 'concept',
      concept_rank: 0,
      concept_unit_label: 'activities',
      custom_due_time: Time.parse('11:30 PM'),
      is_assessment: false,
      is_released_assessment: true,
      lesson_label: 'lesson',
      lesson_rank: 0,
      total_time: 10,
      unit_rank: 0,
      assignment_set_rank: 0,
      activity_concept_rank: 0,
      activity_toc_location_rank: 0
    }
  end
  let(:assignment_bank_class) { StudentDashboardPresenter::AssignmentBank }

  describe '#each' do
    it 'returns each of the banks in the order supplied on initialization' do
      banks = [
        instance_double(assignment_bank_class, bank_stubs),
        instance_double(assignment_bank_class, bank_stubs),
        instance_double(assignment_bank_class, bank_stubs)
      ]
      bank_group = described_class.new(section, banks, student)
      count = 0
      bank_group.each do |bank|
        expect(bank).to be banks[count]
        count += 1
      end
      expect(count).to eq(3)
    end
  end

  describe '#total_time' do
    it 'returns the total minutes across all assignments' do
      banks = [
        instance_double(assignment_bank_class, bank_stubs.merge(total_time: 20)),
        instance_double(assignment_bank_class, bank_stubs.merge(total_time: 100)),
        instance_double(assignment_bank_class, bank_stubs.merge(total_time: 3))
      ]
      bank_group = described_class.new(section, banks, student)

      expect(bank_group.total_time).to eq(123)
    end
  end

  describe '#total_assignments' do
    it 'returns the total count of assignments' do
      banks = [
        instance_double(assignment_bank_class, bank_stubs.merge(activity_count: 3)),
        instance_double(assignment_bank_class, bank_stubs.merge(activity_count: 4)),
        instance_double(assignment_bank_class, bank_stubs.merge(activity_count: 8))
      ]
      bank_group = described_class.new(section, banks, student)

      expect(bank_group.total_assignments).to eq(15)
    end
  end

  describe '#total_label_pluralized' do
    context 'with an activity group,' do
      it "returns 'activity' when there is 1 activity" do
        banks = [
          instance_double(
            assignment_bank_class,
            bank_stubs.merge(activity_count: 1, concept_unit_label: 'activity')
          )
        ]
        bank_group = described_class.new(section, banks, student)

        expect(bank_group.total_label_pluralized).to eq('activity')
      end

      it "returns 'activity' when there are 2 activities" do
        banks = [
          instance_double(
            assignment_bank_class,
            bank_stubs.merge(activity_count: 2, concept_unit_label: 'activity')
          )
        ]
        bank_group = described_class.new(section, banks, student)

        expect(bank_group.total_label_pluralized).to eq('activities')
      end
    end

    context 'with an assessment group,' do
      it "returns 'quiz' when there is 1 quiz" do
        banks = [
          instance_double(
            assignment_bank_class,
            bank_stubs.merge(activity_count: 1, concept_unit_label: 'quiz')
          )
        ]
        bank_group = described_class.new(section, banks, student)

        expect(bank_group.total_label_pluralized).to eq('quiz')
      end

      it "returns 'quizzes' when there are 2 quizzes" do
        banks = [
          instance_double(
            assignment_bank_class,
            bank_stubs.merge(activity_count: 2, concept_unit_label: 'quiz')
          )
        ]
        bank_group = described_class.new(section, banks, student)

        expect(bank_group.total_label_pluralized).to eq('quizzes')
      end
    end
  end

  describe '#can_be_started?' do
    it 'returns true for an activity group' do
      banks = [
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(is_assessment: false, is_released_assessment: false)
        )
      ]
      bank_group = described_class.new(section, banks, student)

      expect(bank_group.can_be_started?).to be_truthy
    end

    it 'returns true for an assessment group that is shown' do
      banks = [
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(is_assessment: true, is_released_assessment: true)
        )
      ]
      bank_group = described_class.new(section, banks, student)

      expect(bank_group.can_be_started?).to be_truthy
    end

    it 'returns false for an assessment group that is not shown' do
      banks = [
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(is_assessment: true, is_released_assessment: false)
        )
      ]
      bank_group = described_class.new(section, banks, student)

      expect(bank_group.can_be_started?).to be_falsey
    end
  end

  describe '#start_path' do
    context 'with an instructor,' do
      it 'returns "#"' do
        instructor = build_stubbed(:instructor)
        bank_group = described_class.new(section, [], instructor, Date.today)

        expect(bank_group.start_path).to eq('#')
      end
    end

    context 'with a student,' do
      it 'returns a duedate workset path for activity groups related to a date' do
        banks = [
          instance_double(
            assignment_bank_class,
            bank_stubs.merge(is_assessment: false, assessment_id: 5)
          )
        ]
        bank_group = described_class.new(section, banks, student, Date.today)

        expect(bank_group.start_path).to eq(
          section_assignment_day_path(section, Date.today)
        )
      end

      it 'returns a pastdue workset path for activity groups not related to a date' do
        banks = [
          instance_double(
            assignment_bank_class,
            bank_stubs.merge(is_assessment: false, assessment_id: 5)
          )
        ]
        bank_group = described_class.new(section, banks, student, nil)

        expect(bank_group.start_path).to eq(
          section_assignment_day_path(section, 'pastdue')
        )
      end

      it 'returns an activity path for assessment groups' do
        banks = [
          instance_double(
            assignment_bank_class,
            bank_stubs.merge(is_assessment: true, assessment_id: 5)
          )
        ]
        bank_group = described_class.new(section, banks, student, Date.today)

        expect(bank_group.start_path).to eq(section_activity_path(section, 5))
      end
    end
  end

  describe '#due_time' do
    let(:assessment_due_time) { section.due_time + 60 }

    it 'returns the section due_time for an activity bank group' do
      banks = [
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            custom_due_time: assessment_due_time,
            is_assessment: false
          )
        )
      ]
      bank_group = described_class.new(section, banks, student, Date.today)

      expect(bank_group.due_time).to eq(section.due_time)
    end

    it 'returns the assessment due_time for an assessment bank group' do
      banks = [
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            custom_due_time: assessment_due_time,
            is_assessment: true
          )
        )
      ]
      bank_group = described_class.new(section, banks, student, Date.today)

      expect(bank_group.due_time).to eq(assessment_due_time)
    end

    it 'returns the section due_time for an assessment bank group with ' \
       'no due time set' do
      banks = [
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(custom_due_time: nil, is_assessment: true)
        )
      ]
      bank_group = described_class.new(section, banks, student, Date.today)

      expect(bank_group.due_time).to eq(section.due_time)
    end
  end

  describe '#time_zone' do
    it 'returns nil if the student and section timezone are the same' do
      section_time_zone = 'Eastern Time (US & Canada)'
      user_time_zone = 'Eastern Time (US & Canada)'
      section.time_zone = section_time_zone
      banks = [
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(is_assessment: true)
        )
      ]
      Time.use_zone(user_time_zone) do
        bank_group = described_class.new(section, banks, student, Date.today)

        expect(bank_group.time_zone).to be_nil
      end
    end

    it 'returns the section timezone if the student and section timezone ' \
       'are different' do
      section_time_zone = 'Pacific Time (US & Canada)'
      user_time_zone = 'Eastern Time (US & Canada)'
      section.time_zone = section_time_zone
      banks = [
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(is_assessment: true)
        )
      ]
      Time.use_zone(user_time_zone) do
        bank_group = described_class.new(section, banks, student, Date.today)

        expect(bank_group.time_zone).to eq(section_time_zone)
      end
    end
  end

  describe '#serialize' do
    let(:section) { create(:section) }
    let(:bank_1) do
      instance_double(
        assignment_bank_class,
        bank_stubs.merge(
          is_assessment: true,
          unit_rank: 2,
          lesson_rank: 1,
          concept_rank: 0,
          assignment_set_rank: 0,
          activity_concept_rank: 0,
          activity_toc_location_rank: 0
        )
      )
    end
    let(:bank_2) do
      instance_double(
        assignment_bank_class,
        bank_stubs.merge(
          is_assessment: true,
          unit_rank: 2,
          lesson_rank: 0,
          concept_rank: 0,
          assignment_set_rank: 0,
          activity_concept_rank: 0,
          activity_toc_location_rank: 0
        )
      )
    end
    let(:bank_3) do
      instance_double(
        assignment_bank_class,
        bank_stubs.merge(
          is_assessment: true,
          unit_rank: 2,
          lesson_rank: 1,
          concept_rank: 1,
          assignment_set_rank: 0,
          activity_concept_rank: 0,
          activity_toc_location_rank: 0
        )
      )
    end
    let(:bank_4) do
      instance_double(
        assignment_bank_class,
        bank_stubs.merge(
          is_assessment: true,
          unit_rank: 1,
          lesson_rank: 1,
          concept_rank: 1,
          assignment_set_rank: 0,
          activity_concept_rank: 0,
          activity_toc_location_rank: 0
        )
      )
    end
    let(:banks) { [bank_1, bank_2, bank_3, bank_4] }
    let(:bank_group) { described_class.new(section, banks, student, Date.today) }
    let(:serialized_bank_1) { { some_key: 'some value bank 1' } }
    let(:serialized_bank_2) { { some_key: 'some value bank 2' } }
    let(:serialized_bank_3) { { some_key: 'some value bank 3' } }
    let(:serialized_bank_4) { { some_key: 'some value bank 4' } }

    before do
      allow(bank_1).to receive(:serialize).and_return(serialized_bank_1)
      allow(bank_2).to receive(:serialize).and_return(serialized_bank_2)
      allow(bank_3).to receive(:serialize).and_return(serialized_bank_3)
      allow(bank_4).to receive(:serialize).and_return(serialized_bank_4)
    end

    it 'returns a hash version of the bank group' do
      expect(bank_group.serialize).to match(
        hash_including(
          can_be_started: bank_group.can_be_started?,
          due_time: bank_group.due_time.strftime('Due %I:%M %p'),
          estimate_time: format_hours_minutes(bank_group.total_time, :short),
          time_zone: bank_group.time_zone,
          total_assignments: bank_group.total_assignments,
          total_label_pluralized: bank_group.total_label_pluralized,
          url: bank_group.start_path
        )
      )
    end

    it 'calls serialize on each bank' do
      bank_group.serialize

      bank_group.each do |bank|
        expect(bank).to have_received(:serialize)
      end
    end

    it 'includes an assignment_banks key with an array of serialized banks ' \
       'ordered by lesson label' do
      expect(bank_group.serialize[:assignment_banks]).to eq(
        [
          serialized_bank_4,
          serialized_bank_2,
          serialized_bank_1,
          serialized_bank_3
        ]
      )
    end

    context 'when there is a custom order for the assignments' do
      let(:bank_1) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 0,
            lesson_rank: 0,
            concept_rank: 0,
            activity_concept_rank: 0,
            activity_toc_location_rank: 0
          )
        )
      end
      let(:bank_2) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 4,
            unit_rank: 0,
            lesson_rank: 0,
            concept_rank: 0,
            activity_concept_rank: 0,
            activity_toc_location_rank: 0
          )
        )
      end
      let(:bank_3) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 2,
            unit_rank: 0,
            lesson_rank: 0,
            concept_rank: 0,
            activity_concept_rank: 0,
            activity_toc_location_rank: 0
          )
        )
      end
      let(:bank_4) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 3,
            unit_rank: 0,
            lesson_rank: 0,
            concept_rank: 0,
            activity_concept_rank: 0,
            activity_toc_location_rank: 0
          )
        )
      end

      it 'includes an assignment_banks key with an array of serialized banks ' \
         'ordered by assignment_set_rank or assignment_rank' do
        expect(bank_group.serialize[:assignment_banks]).to eq(
          [
            serialized_bank_1,
            serialized_bank_3,
            serialized_bank_4,
            serialized_bank_2
          ]
        )
      end
    end

    context 'when there is no custom order for the assignments or assignment_set_rank ' \
            'and assignment_rank tie' do
      let(:bank_1) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 3,
            lesson_rank: 0,
            concept_rank: 0,
            activity_concept_rank: 0,
            activity_toc_location_rank: 0
          )
        )
      end
      let(:bank_2) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 1,
            lesson_rank: 0,
            concept_rank: 0,
            activity_concept_rank: 0,
            activity_toc_location_rank: 0
          )
        )
      end
      let(:bank_3) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 4,
            lesson_rank: 0,
            concept_rank: 0,
            activity_concept_rank: 0,
            activity_toc_location_rank: 0
          )
        )
      end
      let(:bank_4) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 2,
            lesson_rank: 0,
            concept_rank: 0,
            activity_concept_rank: 0,
            activity_toc_location_rank: 0
          )
        )
      end

      it 'includes an assignment_banks key with an array of serialized banks ' \
         'ordered by unit_rank' do
        expect(bank_group.serialize[:assignment_banks]).to eq(
          [
            serialized_bank_2,
            serialized_bank_4,
            serialized_bank_1,
            serialized_bank_3
          ]
        )
      end
    end

    context 'when there is no custom order for the assignments and assignment_set_rank, ' \
            'assignment_rank and unit_rank tie' do
      let(:bank_1) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 1,
            lesson_rank: 4,
            concept_rank: 0,
            activity_concept_rank: 0,
            activity_toc_location_rank: 0
          )
        )
      end
      let(:bank_2) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 1,
            lesson_rank: 2,
            concept_rank: 0,
            activity_concept_rank: 0,
            activity_toc_location_rank: 0
          )
        )
      end
      let(:bank_3) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 1,
            lesson_rank: 1,
            concept_rank: 0,
            activity_concept_rank: 0,
            activity_toc_location_rank: 0
          )
        )
      end
      let(:bank_4) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 1,
            lesson_rank: 3,
            concept_rank: 0,
            activity_concept_rank: 0,
            activity_toc_location_rank: 0
          )
        )
      end

      it 'includes an assignment_banks key with an array of serialized banks ' \
         'ordered by lesson_rank' do
        expect(bank_group.serialize[:assignment_banks]).to eq(
          [
            serialized_bank_3,
            serialized_bank_2,
            serialized_bank_4,
            serialized_bank_1
          ]
        )
      end
    end

    context 'when there is no custom order for the assignments and assignment_set_rank, ' \
            'assignment_rank, unit_rank and lesson_rank tie' do
      let(:bank_1) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 1,
            lesson_rank: 1,
            concept_rank: 4,
            activity_concept_rank: 0,
            activity_toc_location_rank: 0
          )
        )
      end
      let(:bank_2) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 1,
            lesson_rank: 1,
            concept_rank: 3,
            activity_concept_rank: 0,
            activity_toc_location_rank: 0
          )
        )
      end
      let(:bank_3) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 1,
            lesson_rank: 1,
            concept_rank: 2,
            activity_concept_rank: 0,
            activity_toc_location_rank: 0
          )
        )
      end
      let(:bank_4) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 1,
            lesson_rank: 1,
            concept_rank: 1,
            activity_concept_rank: 0,
            activity_toc_location_rank: 0
          )
        )
      end

      it 'includes an assignment_banks key with an array of serialized banks ' \
         'ordered by concept_rank' do
        expect(bank_group.serialize[:assignment_banks]).to eq(
          [
            serialized_bank_4,
            serialized_bank_3,
            serialized_bank_2,
            serialized_bank_1
          ]
        )
      end
    end

    context 'when there is no custom order for the assignments and assignment_set_rank, ' \
            'assignment_rank, unit_rank, lesson_rank and concept_rank tie' do
      let(:bank_1) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 1,
            lesson_rank: 1,
            concept_rank: 1,
            activity_concept_rank: 3,
            activity_toc_location_rank: 0
          )
        )
      end
      let(:bank_2) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 1,
            lesson_rank: 1,
            concept_rank: 1,
            activity_concept_rank: 1,
            activity_toc_location_rank: 0
          )
        )
      end
      let(:bank_3) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 1,
            lesson_rank: 1,
            concept_rank: 1,
            activity_concept_rank: 2,
            activity_toc_location_rank: 0
          )
        )
      end
      let(:bank_4) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 1,
            lesson_rank: 1,
            concept_rank: 1,
            activity_concept_rank: 4,
            activity_toc_location_rank: 0
          )
        )
      end

      it 'includes an assignment_banks key with an array of serialized banks ' \
         'ordered by activity_concept_rank' do
        expect(bank_group.serialize[:assignment_banks]).to eq(
          [
            serialized_bank_2,
            serialized_bank_3,
            serialized_bank_1,
            serialized_bank_4
          ]
        )
      end
    end

    context 'when there is no custom order for the assignments and assignment_set_rank, ' \
            'assignment_rank, unit_rank, lesson_rank, concept_rank and activity_concept_rank tie' do
      let(:bank_1) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 1,
            lesson_rank: 1,
            concept_rank: 1,
            activity_concept_rank: 1,
            activity_toc_location_rank: 1
          )
        )
      end
      let(:bank_2) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 1,
            lesson_rank: 1,
            concept_rank: 1,
            activity_concept_rank: 1,
            activity_toc_location_rank: 2
          )
        )
      end
      let(:bank_3) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 1,
            lesson_rank: 1,
            concept_rank: 1,
            activity_concept_rank: 1,
            activity_toc_location_rank: 3
          )
        )
      end
      let(:bank_4) do
        instance_double(
          assignment_bank_class,
          bank_stubs.merge(
            is_assessment: false,
            assignment_set_rank: 1,
            unit_rank: 1,
            lesson_rank: 1,
            concept_rank: 1,
            activity_concept_rank: 1,
            activity_toc_location_rank: 4
          )
        )
      end

      it 'includes an assignment_banks key with an array of serialized banks ' \
         'ordered by activity_toc_location_rank' do
        expect(bank_group.serialize[:assignment_banks]).to eq(
          [
            serialized_bank_1,
            serialized_bank_2,
            serialized_bank_3,
            serialized_bank_4
          ]
        )
      end
    end
  end
end

describe StudentDashboardPresenter::AssignmentBank do
  include DateTimeHelper

  let(:course) { create(:course) }

  let(:section) do
    create(:section, course: course, time_zone: 'Eastern Time (US & Canada)')
  end

  let(:result_class) do
    Struct.new(
      :activity_count,
      :assessment_id,
      :availability_message,
      :background_color,
      :concept_name,
      :concept_rank,
      :concept_unit_label,
      :custom_due_time,
      :is_assessment,
      :lesson_label,
      :lesson_name,
      :lesson_rank,
      :show_at,
      :total_time,
      :unit_rank,
      :assignment_set_rank,
      :activity_concept_rank,
      :activity_toc_location_rank
    )
  end

  let(:result) do
    result_class.new(
      activity_count: 5,
      assessment_id: 5000,
      background_color: '#aabbcc',
      concept_name: 'Activity Concept',
      concept_rank: 0,
      concept_unit_label: 'activity',
      custom_due_time: Time.parse('11:30 PM'),
      is_assessment: false,
      lesson_label: 'Lesson 1',
      lesson_name: 'Lesson Name',
      lesson_rank: 0,
      show_at: nil,
      total_time: 10,
      unit_rank: 0,
      assignment_set_rank: 0,
      activity_concept_rank: 0,
      activity_toc_location_rank: 0
    )
  end

  let(:assignment_bank) { described_class.new(result, section) }

  describe '#lesson_label' do
    it 'returns the lesson_label from the result' do
      expect(assignment_bank.lesson_label).to be result.lesson_label
    end

    context 'when the lesson has no label' do
      it 'returns the lesson name' do
        result.lesson_label = ''
        assignment_bank = described_class.new(result, section)
        expect(assignment_bank.lesson_label).to be result.lesson_name
      end
    end
  end

  describe '#concept_name' do
    it 'returns the concept_name from the result' do
      expect(assignment_bank.concept_name).to be result.concept_name
    end
  end

  describe '#background_color' do
    it 'returns the background_color from the result' do
      expect(assignment_bank.background_color).to be result.background_color
    end
  end

  describe '#concept_unit_label' do
    it 'returns the concept_unit_label from the result' do
      expect(assignment_bank.concept_unit_label).to be result.concept_unit_label
    end
  end

  describe '#activity_count' do
    it 'returns the activity_count from the result' do
      expect(assignment_bank.activity_count).to be result.activity_count
    end
  end

  describe '#total_time' do
    it 'returns the total_time from the result' do
      expect(assignment_bank.total_time).to eq(result.total_time)
    end
  end

  describe '#is_assessment' do
    it 'returns the is_assessment from the result' do
      expect(assignment_bank.is_assessment).to eq(result.is_assessment)
    end
  end

  describe '#availability_message' do
    context 'when the assessment is set to be released manually and has not ' \
            'been released,' do
      it 'returns a message that the assessment will be available when ' \
         'instructor releases it' do
        result.is_assessment = true
        result.show_at = nil

        expect(assignment_bank.availability_message).to eq(
          'This assessment will be available when your instructor releases it'
        )
      end
    end

    context 'when the assessment will be released on a future date,' do
      it 'returns a message with the release date' do
        result.is_assessment = true
        result.show_at = 1.hour.from_now

        expect(assignment_bank.availability_message).to eq(
          'This assessment will be available on ' \
          "#{format_date_time(result.show_at)} at " \
          "#{format_date_time(result.show_at, :time_with_zone)}"
        )
      end
    end

    context 'when the assessment has already been released,' do
      it 'returns a message that the assessment is available' do
        result.is_assessment = true
        result.show_at = 1.hour.ago

        expect(assignment_bank.availability_message).to eq(
          'This assessment is available to start'
        )
      end
    end
  end

  describe '#is_released_assessment' do
    it 'returns true if the assessment was set to be shown before now' do
      result.is_assessment = true
      result.show_at = 1.hour.ago

      expect(assignment_bank.is_released_assessment).to be true
    end

    it 'returns false if the assessment was set to be shown after now' do
      result.is_assessment = true
      result.show_at = 1.hour.from_now

      expect(assignment_bank.is_released_assessment).to be false
    end

    it 'returns true if the assessment was not set to be shown' do
      result.is_assessment = true
      result.show_at = nil

      expect(assignment_bank.is_released_assessment).to be false
    end
  end

  describe '#assessment_id' do
    it 'returns the assessment_id from the result' do
      expect(assignment_bank.assessment_id).to eq(result.assessment_id)
    end
  end

  describe '#activity_count_text' do
    it 'returns the singular form when only 1 activity is in the bank' do
      result.activity_count = 1

      expect(assignment_bank.activity_count_text).to match '1 activity'
    end

    it 'returns the plural form when when 2 activities are in the bank' do
      result.activity_count = 5

      expect(assignment_bank.activity_count_text).to match '5 activities'
    end

    it 'returns an empty string for an assessment' do
      result.is_assessment = true

      expect(assignment_bank.activity_count_text).to match ''
    end
  end

  describe '#custom_due_time' do
    it 'returns the due_time from the result' do
      expect(assignment_bank.custom_due_time).to eq(result.custom_due_time)
    end
  end

  describe '#serialize' do
    it 'returns a hash version of the bank' do
      expect(assignment_bank.serialize[:lesson_label]).to eq(assignment_bank.lesson_label)
      expect(assignment_bank.serialize[:concept_name]).to eq(assignment_bank.concept_name)
      expect(assignment_bank.serialize[:assessment_id]).to eq(assignment_bank.assessment_id)
      expect(assignment_bank.serialize[:availability_message]).to eq(assignment_bank.availability_message)
      expect(assignment_bank.serialize[:activity_count_text]).to eq(assignment_bank.activity_count_text)
    end

    context 'when bank does not have background color set,' do
      it 'returns an empty string for the background_color key' do
        result.background_color = nil

        expect(assignment_bank.serialize[:background_color]).to eq('')
      end
    end
  end
end
