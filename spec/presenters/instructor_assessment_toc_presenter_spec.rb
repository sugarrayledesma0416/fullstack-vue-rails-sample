describe InstructorAssessmentTocPresenter do
  include Rails.application.routes.url_helpers
  include ApplicationHelper

  let(:program) { build_stubbed(:program) }
  let(:course) { build_stubbed(:course, program: program) }
  let(:section) do
    build_stubbed(
      :section,
      time_zone: 'Pacific Time (US & Canada)',
      course: course
    )
  end
  let(:lesson) { build_stubbed(:lesson_with_toc_entries) }
  let(:activity) { build_stubbed(:activity) }
  let(:assignment) do
    build_stubbed(:assignment, assignable: activity, section: section)
  end
  let(:assignments) { [assignment] }
  let(:current_focus) do
    instance_double(Focus, course: section.course, sections: [section])
  end
  let(:required_params) do
    {
      start_unit: 'start_unit',
      display_lesson: 'display_lesson',
      toc_location: 'some location',
      all_units: 'true'
    }
  end
  let(:presenter) do
    described_class.new(
      program,
      current_focus,
      'instructor',
      required_params,
      {}
    )
  end
  let(:instructor) { create(:instructor) }
  let(:presenter_with_instructor) do
    described_class.new(
      program,
      current_focus,
      instructor,
      required_params,
      {}
    )
  end

  before do
    allow(program).to receive(:best_display_lesson).and_return(lesson)
    allow(lesson).to receive(:program).and_return(program)
    allow(section).to receive(:program).and_return(program)
  end

  describe '.new' do
    it 'inits current_user' do
      expect(presenter.current_user).to eq('instructor')
    end

    it 'inits program' do
      expect(presenter.program).to eq(program)
    end

    it 'inits sections' do
      expect(presenter.sections).to eq([section])
    end

    it 'raises error when valid params are not passed' do
      expect do
        described_class.new(nil, current_focus, 'instructor', {}, {})
      end.to raise_error 'not all parameters are valid'

      expect do
        described_class.new(program, current_focus, nil, {}, {})
      end.to raise_error 'not all parameters are valid'

      expect do
        described_class.new(program, current_focus, 'user', nil, {})
      end.to raise_error 'not all parameters are valid'
    end
  end

  describe '#max_attempts' do
    it 'returns the maximum of attempts for a given activity' do
      max_attempt_policy = instance_double(MaxAttemptPolicy, max_attempts: 11)
      expect(MaxAttemptPolicy).to receive(:new)
        .with(activity, assignment)
        .and_return(max_attempt_policy)
      allow(presenter).to receive(:assignments).and_return([assignment])

      expect(presenter.max_attempts(activity)).to eq(11)
    end
  end

  describe '#has_assignments_for?' do
    it 'is true if there are assignments for the specified activity' do
      allow(presenter).to receive(:assignments).and_return([assignment])

      expect(presenter.has_assignments_for?(activity)).to be_truthy
    end

    it 'is false if there are no assignments' do
      allow(presenter).to receive(:assignments).and_return([])

      expect(presenter.has_assignments_for?(activity)).to be_falsey
    end

    it 'is false if there are only assignments for activities other than ' \
       'the specified activity' do
      activity_2 = build_stubbed(:activity)
      allow(presenter).to receive(:assignments).and_return([assignment])

      expect(presenter.has_assignments_for?(activity_2)).to be_falsey
    end
  end

  describe '#assessment_availability' do
    before do
      allow(activity).to receive(:strand_singular_label).and_return('quiz')
    end

    it 'returns empty string when the assessment is not assigned' do
      allow(presenter).to receive(:assignments).and_return([])
      expect(presenter.assessment_availability(activity)).to eq ''
    end

    context 'when there is only one assignment,' do
      before do
        allow(presenter).to receive(:assignments).and_return([assignment])
      end

      it 'returns status of shown and uses the singular assessment label ' \
         'when assignment is available' do
        allow(assignment).to receive(:shown?).and_return(true)
        expect(presenter.assessment_availability(activity)).to eq 'Yes'
      end

      it 'returns status of hidden and uses the singular assessment label ' \
         'when assignment is not available' do
        allow(assignment).to receive(:shown?).and_return(false)
        expect(presenter.assessment_availability(activity)).to eq 'No'
      end
    end

    context 'when there are multiple assignments,' do
      let(:assignment_2) { build_stubbed(:assignment, assignable: activity) }

      before do
        allow(presenter).to receive(:assignments)
          .and_return([assignment, assignment_2])
      end

      it 'returns status of shown and uses the singular assessment label ' \
         'when all assignments are available' do
        allow(assignment).to receive(:shown?).and_return(true)
        allow(assignment_2).to receive(:shown?).and_return(true)
        expect(presenter.assessment_availability(activity)).to eq 'Yes'
      end

      it 'returns status of hidden and uses the singular assessment label ' \
         'when assignments are not available' do
        allow(assignment).to receive(:shown?).and_return(false)
        allow(assignment_2).to receive(:shown?).and_return(false)
        expect(presenter.assessment_availability(activity)).to eq 'No'
      end

      it 'returns varies if assignments have different values' do
        allow(assignment).to receive(:shown?).and_return(true)
        allow(assignment_2).to receive(:shown?).and_return(false)

        expect(presenter.assessment_availability(activity)).to eq 'Varies'

        allow(presenter).to receive(:assignments)
          .and_return([assignment_2, assignment])
        expect(presenter.assessment_availability(activity)).to eq 'Varies'
      end
    end
  end

  describe '#assessment_grade_availability' do
    it 'returns empty string when the assessment is not assigned' do
      allow(presenter).to receive(:assignments).and_return([])
      expect(presenter.assessment_grade_availability(activity)).to eq ''
    end

    context 'when there is only one assignment,' do
      before do
        allow(presenter).to receive(:assignments).and_return([assignment])
      end

      it 'returns status of shown when assignment grades are available' do
        allow(assignment).to receive(:assessment_grade_available?)
          .and_return(true)
        expect(presenter.assessment_grade_availability(activity)).to eq 'Yes'
      end

      it 'returns status of hidden when assignment grades are not available' do
        allow(assignment).to receive(:assessment_grade_available?)
          .and_return(false)
        expect(presenter.assessment_grade_availability(activity)).to eq 'No'
      end
    end

    context 'when there are multiple assignments,' do
      let(:assignment_2) { build_stubbed(:assignment, assignable: activity) }

      before do
        allow(presenter).to receive(:assignments)
          .and_return([assignment, assignment_2])
      end

      it 'returns status of shown when grades for all assignments are available' do
        allow(assignment).to receive(:assessment_grade_available?)
          .and_return(true)
        allow(assignment_2).to receive(:assessment_grade_available?)
          .and_return(true)

        expect(presenter.assessment_grade_availability(activity)).to eq 'Yes'
      end

      it 'returns status of hidden when grades for all assignments are not available' do
        allow(assignment).to receive(:assessment_grade_available?)
          .and_return(false)
        allow(assignment_2).to receive(:assessment_grade_available?)
          .and_return(false)

        expect(presenter.assessment_grade_availability(activity)).to eq 'No'
      end

      it 'returns varies if assignments have different grade availability values' do
        allow(assignment).to receive(:assessment_grade_available?)
          .and_return(true)
        allow(assignment_2).to receive(:assessment_grade_available?)
          .and_return(false)

        expect(presenter.assessment_grade_availability(activity)).to eq 'Varies'

        allow(presenter).to receive(:assignments)
          .and_return([assignment_2, assignment])
        expect(presenter.assessment_grade_availability(activity)).to eq 'Varies'
      end
    end
  end

  describe '#show_release_link_for?' do
    it 'is false when the assessment is not assigned' do
      allow(presenter).to receive(:assignments).and_return([])

      expect(presenter.show_release_link_for?(activity)).to be_falsey
    end

    context 'when there is only one assignment,' do
      before do
        allow(presenter).to receive(:assignments).and_return([assignment])
      end

      it 'is true when the assignment is set to be available on release' do
        allow(assignment).to receive(:show_assessment)
          .and_return('I release it')

        expect(presenter.show_release_link_for?(activity)).to be_truthy
      end

      it 'is false when the assignment is not set to be available on release' do
        allow(assignment).to receive(:show_assessment)
          .and_return('a specific date and time')

        expect(presenter.show_release_link_for?(activity)).to be_falsey
      end
    end

    context 'when there are multiple assignments,' do
      let(:assignment_2) { build_stubbed(:assignment, assignable: activity) }

      before do
        allow(presenter).to receive(:assignments)
          .and_return([assignment, assignment_2])
      end

      it 'is false when no assignments are set to be available on release' do
        allow(assignment).to receive(:show_assessment)
          .and_return('a specific date and time')
        allow(assignment_2).to receive(:show_assessment)
          .and_return('a specific date and time')

        expect(presenter.show_release_link_for?(activity)).to be_falsey
      end

      it 'is true if any assignment is set to be available on release' do
        allow(assignment).to receive(:show_assessment)
          .and_return('a specific date and time')
        allow(assignment_2).to receive(:show_assessment)
          .and_return('I release it')

        expect(presenter.show_release_link_for?(activity)).to be_truthy

        allow(presenter).to receive(:assignments)
          .and_return([assignment_2, assignment])
        expect(presenter.show_release_link_for?(activity)).to be_truthy
      end
    end
  end

  describe '#show_grades_release_link_for?' do
    it 'is false when the assessment is not assigned' do
      allow(presenter).to receive(:assignments).and_return([])

      expect(presenter.show_grades_release_link_for?(activity)).to be_falsey
    end

    context 'when there is only one assignment,' do
      before do
        allow(presenter).to receive(:assignments).and_return([assignment])
      end

      it 'is true when the assignment has grades set to be available on release' do
        allow(assignment).to receive(:grade_availability)
          .and_return(:on_release)

        expect(presenter.show_grades_release_link_for?(activity)).to be_truthy
      end

      it 'is false when the assignment does not have grades set to be available on release' do
        allow(assignment).to receive(:grade_availability)
          .and_return(:on_due_date)

        expect(presenter.show_grades_release_link_for?(activity)).to be_falsey
      end
    end

    context 'when there are multiple assignments,' do
      let(:assignment_2) { build_stubbed(:assignment, assignable: activity) }

      before do
        allow(presenter).to receive(:assignments)
          .and_return([assignment, assignment_2])
      end

      it 'is false when no assignments have grades set to be available on release' do
        allow(assignment).to receive(:grade_availability)
          .and_return(:on_due_date)
        allow(assignment_2).to receive(:grade_availability)
          .and_return(:on_due_date)

        expect(presenter.show_grades_release_link_for?(activity)).to be_falsey
      end

      it 'is true if grades for any assignment are set to be available on release' do
        allow(assignment).to receive(:grade_availability)
          .and_return(:on_due_date)
        allow(assignment_2).to receive(:grade_availability)
          .and_return(:on_release)

        expect(presenter.show_grades_release_link_for?(activity)).to be_truthy

        allow(presenter).to receive(:assignments)
          .and_return([assignment_2, assignment])

        expect(presenter.show_grades_release_link_for?(activity)).to be_truthy
      end
    end
  end

  describe '#release_link_text' do
    before do
      allow(presenter).to receive(:assignments).and_return([assignment])
    end

    context 'when checking assessment release,' do
      context 'when assignment is shown,' do
        it 'returns link options to hide the assignment' do
          assignment.show_at = nil
          expected_result = 'Release'
          expect(
            presenter.release_link_text(activity, 'assessment_release')
          ).to eq expected_result
        end
      end

      context 'when the assignment is not shown,' do
        it 'returns link options to show the assignment' do
          assignment.show_at = Time.now
          expected_result = 'Hide'
          expect(
            presenter.release_link_text(activity, 'assessment_release')
          ).to eq expected_result
        end
      end
    end

    context 'when checking grades release,' do
      context 'when assignment is shown,' do
        it 'returns link options to hide the grades' do
          assignment.grades_available_at = nil
          expected_result = 'Release'
          expect(
            presenter.release_link_text(activity, 'grade_release')
          ).to eq expected_result
        end
      end

      context 'when the assignment is not shown,' do
        it 'returns link options to show the grades' do
          assignment.grades_available_at = Time.now
          expected_result = 'Hide'
          expect(
            presenter.release_link_text(activity, 'grade_release')
          ).to eq expected_result
        end
      end
    end
  end

  describe '#grades_available?' do
    let(:activity) { instance_double(Activity) }
    let(:assignments) do
      [
        instance_double(
          Assignment,
          section: section,
          grades_available_at: Time.parse('2000-01-01')
        ),
        instance_double(
          Assignment,
          section: section,
          grades_available_at: Time.parse('2000-01-02')
        ),
        instance_double(
          Assignment,
          section: section,
          grades_available_at: nil
        )
      ]
    end

    before do
      allow(presenter).to receive(:assignments_for_activity)
        .with(activity)
        .and_return(assignments)
    end

    context 'when any assignments have released grades,' do
      it 'returns true' do
        Timecop.freeze(Time.parse('2000-01-01')) do
          expect(presenter.grades_available?(activity)).to be_truthy
        end
      end
    end

    context 'when all assignments have not released grades,' do
      it 'returns false' do
        Timecop.freeze(Time.parse('1999-12-31')) do
          expect(presenter.grades_available?(activity)).to be_falsey
        end
      end
    end
  end

  describe '#assessment_release_link_hover_text' do
    context 'when grades are available for the assignments' do
      it 'returns a string explaining why the assignments cannot be released' do
        activity = instance_double(Activity)
        expect(presenter).to receive(:grades_available?)
          .with(activity)
          .and_return(true)
        msg = 'Availability cannot be changed after results have been released.'
        expect(presenter.assessment_release_link_hover_text(activity)).to eq(msg)
      end
    end

    context 'when grades are not availalable for the assignments' do
      it 'returns the empty string' do
        activity = instance_double(Activity)
        expect(presenter).to receive(:grades_available?)
          .with(activity)
          .and_return(false)
        expect(presenter.assessment_release_link_hover_text(activity)).to eq('')
      end
    end
  end

  describe '#release_link_assignment' do
    it 'finds the first assignment for the given activity' do
      expect(presenter).to receive(:assignments_for_activity)
        .and_return([instance_double(Assignment)])
      presenter.release_link_assignment(instance_double(Activity))
    end
  end

  describe '#availability_status_for' do
    it 'returns empty string when the assessment is not assigned' do
      allow(presenter).to receive(:assignments).and_return([])

      expect(presenter.availability_status_for(activity)).to eq ''
    end

    context 'when there is only one assignment,' do
      it 'returns the show_at date formatted as a compact date and time' do
        allow(presenter).to receive(:assignments).and_return([assignment])
        show_at = Time.now
        expected_result = format_date_time(
          show_at,
          :compact_date_and_time,
          assignment.section.time_zone
        )
        allow(assignment).to receive(:show_at).and_return(show_at)

        expect(presenter.availability_status_for(activity)).to eq expected_result
      end
    end

    context 'when there are multiple assignments,' do
      let(:assignment_2) { build_stubbed(:assignment, assignable: activity) }

      before do
        allow(presenter).to receive(:assignments)
          .and_return([assignment, assignment_2])
      end

      context 'when the assignments have different visibility' do
        it 'returns an empty string' do
          allow(assignment).to receive(:shown?).and_return(true)
          allow(assignment_2).to receive(:shown?).and_return(false)

          allow(assignment).to receive(:show_at).and_return(Time.zone.today)
          allow(assignment_2).to receive(:show_at).and_return(Time.zone.tomorrow)

          expect(presenter.availability_status_for(activity)).to eq ''

          allow(presenter).to receive(:assignments)
            .and_return([assignment_2, assignment])
          expect(presenter.availability_status_for(activity)).to eq ''
        end
      end

      context 'when assignments have the same visibility,' do
        before do
          allow(assignment).to receive(:shown?).and_return(true)
          allow(assignment_2).to receive(:shown?).and_return(true)
        end

        it 'returns the common show_at date formatted as a compact date ' \
           'and time when all assignments have the same show_at value' do
          common_show_at = Time.now
          expected_result = format_date_time(
            common_show_at,
            :compact_date_and_time,
            assignment.section.time_zone
          )
          allow(assignment).to receive(:show_at).and_return(common_show_at)
          allow(assignment_2).to receive(:show_at).and_return(common_show_at)

          expect(presenter.availability_status_for(activity)).to eq expected_result
        end

        it 'returns varies if assignments have different values for show_at' do
          allow(assignment).to receive(:show_at).and_return(Time.zone.today)
          allow(assignment_2).to receive(:show_at).and_return(Time.zone.tomorrow)

          expect(presenter.availability_status_for(activity)).to eq 'Varies'

          allow(presenter).to receive(:assignments)
            .and_return([assignment_2, assignment])
          expect(presenter.availability_status_for(activity)).to eq 'Varies'
        end
      end
    end
  end

  describe '#grade_availability_status_for' do
    it 'returns empty string when the assessment is not assigned' do
      allow(presenter).to receive(:assignments).and_return([])
      expect(presenter.grade_availability_status_for(activity)).to eq ''
    end

    context 'when there is only one assignment,' do
      before do
        allow(presenter).to receive(:assignments).and_return([assignment])
      end

      it "returns 'Never' when assignment's grade availability is set to 'never'" do
        assignment.grade_availability = 'never'
        expect(presenter.grade_availability_status_for(activity)).to eq 'Never'
      end

      it "returns the formatted grade availability date when assignment's " \
         "grade availability is set to 'on_specific_date'" do
        assignment.grade_availability = 'on_specific_date'
        assignment.grades_available_at = Time.now
        expect(presenter.grade_availability_status_for(activity)).to eq(
          format_date_time(
            assignment.grades_available_at,
            :compact_date_and_time,
            assignment.section.time_zone
          )
        )
      end

      it "returns the formatted due date and time when assignment's " \
         "grade availability is set to 'on_due_date'" do
        assignment.grade_availability = 'on_due_date'
        allow(assignment).to receive(:due_date_time).and_return(Time.now)
        expect(presenter.grade_availability_status_for(activity)).to eq(
          format_date_time(
            assignment.due_date_time,
            :compact_date_and_time,
            assignment.section.time_zone
          )
        )
      end

      it "returns 'After grading' when assignment's grade availability " \
         "is set to 'on_grading'" do
        assignment.grade_availability = 'on_grading'
        expect(
          presenter.grade_availability_status_for(activity)
        ).to eq 'After grading'
      end
    end

    context 'when there are multiple assignments,' do
      let(:assignment_2) { build_stubbed(:assignment, assignable: activity) }

      before do
        allow(presenter).to receive(:assignments)
          .and_return([assignment, assignment_2])
      end

      context 'when current grade availability is different for the assignments,' do
        it 'returns an empty string' do
          allow(assignment).to receive(:assessment_grade_available?)
            .and_return(true)
          allow(assignment_2).to receive(:assessment_grade_available?)
            .and_return(false)

          expect(presenter.grade_availability_status_for(activity)).to eq ''

          allow(presenter).to receive(:assignments)
            .and_return([assignment_2, assignment])
          expect(presenter.grade_availability_status_for(activity)).to eq ''
        end
      end

      context 'when current grade availability is the same for all assignments,' do
        before do
          allow(assignment).to receive(:assessment_grade_available?)
            .and_return(true)
          allow(assignment_2).to receive(:assessment_grade_available?)
            .and_return(true)
        end

        it 'returns varies if assignments have different dates for when ' \
           'the grades became available' do
          assignment.grade_availability = 'on_specific_date'
          assignment.grades_available_at = 1.day.ago

          assignment_2.grade_availability = 'on_specific_date'
          assignment.grades_available_at = 2.days.ago

          expect(presenter.grade_availability_status_for(activity)).to eq 'Varies'

          allow(presenter).to receive(:assignments)
            .and_return([assignment_2, assignment])
          expect(presenter.grade_availability_status_for(activity)).to eq 'Varies'
        end

        context 'when the assignments have a common value for grade_availability,' do
          it "returns 'Never' when assignment's common grade availability is set to 'never'" do
            assignment.grade_availability = 'never'
            assignment_2.grade_availability = 'never'

            expect(presenter.grade_availability_status_for(activity)).to eq 'Never'
          end

          it 'returns the formatted grade availability date when ' \
             "assignment's common grade availability is set to 'on_specific_date'" do
            assignment.grade_availability = 'on_specific_date'
            assignment_2.grade_availability = 'on_specific_date'

            assignment.grades_available_at = Time.now
            assignment_2.grades_available_at = assignment.grades_available_at

            expect(presenter.grade_availability_status_for(activity)).to eq(
              format_date_time(
                assignment.grades_available_at,
                :compact_date_and_time,
                assignment.section.time_zone
              )
            )
          end

          it "returns the formatted due date and time when assignment's " \
             "common grade availability is set to 'on_due_date'" do
            assignment.grade_availability = 'on_due_date'
            assignment_2.grade_availability = 'on_due_date'

            allow(assignment).to receive(:due_date_time)
              .and_return(Time.now)
            allow(assignment_2).to receive(:due_date_time)
              .and_return(assignment.due_date_time)
            expect(presenter.grade_availability_status_for(activity)).to eq(
              format_date_time(
                assignment.due_date_time,
                :compact_date_and_time,
                assignment.section.time_zone
              )
            )
          end

          it "returns 'After grading' when assignment's common grade " \
             "availability is set to 'on_grading'" do
            assignment.grade_availability = 'on_grading'
            assignment_2.grade_availability = 'on_grading'

            expect(
              presenter.grade_availability_status_for(activity)
            ).to eq 'After grading'
          end
        end
      end
    end
  end

  describe '#password_protected?' do
    context 'when all assessments are password protected' do
      it 'returns true' do
        assignment_1 = instance_double(Assignment, has_password?: true)
        assignment_2 = instance_double(Assignment, has_password?: true)
        allow(presenter).to receive(:assignments_for_activity)
          .and_return([assignment_1, assignment_2])
        expect(presenter.password_protected?(activity)).to eq('Yes')
      end
    end

    context 'when some assessments are password protected' do
      it 'returns true' do
        assignment_1 = instance_double(Assignment, has_password?: true)
        assignment_2 = instance_double(Assignment, has_password?: false)
        allow(presenter).to receive(:assignments_for_activity)
          .and_return([assignment_1, assignment_2])
        expect(presenter.password_protected?(activity)).to eq('Varies')
      end
    end

    context 'when all assessments are not password protected' do
      it 'returns false' do
        assignment_1 = instance_double(Assignment, has_password?: false)
        assignment_2 = instance_double(Assignment, has_password?: false)
        allow(presenter).to receive(:assignments_for_activity)
          .and_return([assignment_1, assignment_2])
        expect(presenter.password_protected?(activity)).to eq('No')
      end
    end
  end

  describe '#time_limit_for' do
    context 'when all assessments have the same time limit,' do
      it 'returns the time limit' do
        assignment_1 = instance_double(Assignment, time_limit: 100)
        assignment_2 = instance_double(Assignment, time_limit: 100)
        allow(presenter).to receive(:assignments_for_activity)
          .and_return([assignment_1, assignment_2])
        expect(presenter.time_limit_for(activity)).to eq(100)
      end
    end

    context 'when assessments have different time limits,' do
      it 'returns Varies' do
        assignment_1 = instance_double(Assignment, time_limit: 100)
        assignment_2 = instance_double(Assignment, time_limit: 200)
        allow(presenter).to receive(:assignments_for_activity)
          .and_return([assignment_1, assignment_2])
        expect(presenter.time_limit_for(activity)).to eq('Varies')
      end
    end

    context 'when all assessments have no time limit,' do
      it 'returns None' do
        assignment_1 = instance_double(Assignment, time_limit: 0)
        assignment_2 = instance_double(Assignment, time_limit: 0)
        allow(presenter_with_instructor).to receive(:assignments_for_activity)
          .and_return([assignment_1, assignment_2])
        expect(presenter_with_instructor.time_limit_for(activity)).to eq('None')
      end
    end
  end

  describe '#display_lesson' do
    before do
      allow(presenter_with_instructor).to receive(:trial_access?).and_return(false)
    end

    context 'when presenter has sections,' do
      it 'returns section units' do
        expect(section).to receive(:units).with('true')
        presenter_with_instructor.display_lesson
      end
    end

    context 'when presenter has no sections,' do
      it "returns units based on the program's best display lesson outcome" do
        expect(program).to receive(:best_display_lesson)
        presenter_with_instructor.display_lesson
      end
    end
  end

  describe '#current_strand' do
    context 'with parallel toc location' do
      it "gets current_strand from display lesson's parallel toc location" do
        allow(lesson).to receive(:parallel_toc_location)
          .and_return('some location')
        expect(presenter).to receive(:display_lesson).and_return(lesson)
        expect(lesson).to receive(:parallel_toc_location)
        expect(lesson).not_to receive(:most_relevant_strand)
        presenter.current_strand
      end
    end

    context 'without parallel toc location' do
      it "gets current_strand from display lesson's most relevant strand" do
        allow(lesson).to receive(:most_relevant_strand)
          .and_return(instance_double('strand', location: 'some location'))
        allow(lesson).to receive(:parallel_toc_location).and_return(false)
        allow(presenter).to receive(:display_lesson).and_return(lesson)
        expect(lesson).to receive(:most_relevant_strand)
        presenter.current_strand
      end
    end
  end

  describe '#current_topic' do
    context 'with parallel toc location' do
      it "gets current_topic from display lesson's parallel toc location" do
        allow(lesson).to receive(:parallel_toc_location).and_return('some location')
        expect(presenter).to receive(:display_lesson).and_return(lesson)
        expect(lesson).to receive(:parallel_toc_location)
        expect(lesson).not_to receive(:most_relevant_strand)
        presenter.current_topic
      end
    end

    context 'without parallel toc location' do
      it "gets current_topic from display lesson's most relevant topic" do
        allow(lesson).to receive(:most_relevant_topic)
        allow(lesson).to receive(:parallel_toc_location).and_return(false)
        allow(presenter).to receive(:display_lesson).and_return(lesson)
        expect(lesson).to receive(:most_relevant_topic)
        presenter.current_topic
      end
    end
  end

  describe '#activities' do
    let(:visible_activity_1) { create(:activity) }
    let(:visible_activity_2) { create(:activity) }
    let(:visible_instructor_activity_1) { create(:activity, instructor_revision_id: 1) }
    let(:visible_activities) do
      [
        visible_activity_1,
        visible_activity_2,
        visible_instructor_activity_1
      ]
    end
    let(:hidden_activity_1) { create(:activity) }
    let(:hidden_activity_2) { create(:activity) }
    let(:hidden_instructor_activity_1) { create(:activity, instructor_revision_id: 1) }
    let(:hidden_activities) do
      [
        hidden_activity_1,
        hidden_activity_2,
        hidden_instructor_activity_1
      ]
    end
    let(:activity_scope) { instance_double(ActiveRecord::Relation).as_null_object }

    before do
      allow(lesson).to receive(:strands)
        .and_return([instance_double('strand', location: 'some location')])
      allow(presenter_with_instructor).to receive(:trial_access?).and_return(false)

      allow(Services::TocActivityList).to receive(:all_for_toc_location)
        .with('some location', sections: [section], current_user: instructor)
        .and_return(
          visible_activities.map(&:id) + hidden_activities.map(&:id)
        )
    end

    it 'looks up activities' do
      allow(presenter_with_instructor).to receive(:current_topic).and_return('some location')

      expect(presenter_with_instructor.activities).to contain_exactly(
        visible_activity_1,
        visible_activity_2,
        visible_instructor_activity_1,
        hidden_activity_1,
        hidden_activity_2,
        hidden_instructor_activity_1
      )
    end

    it 'returns empty array if lesson does not have strands' do
      allow(presenter_with_instructor.display_lesson).to receive(:strands).and_return([])

      expect(presenter_with_instructor.activities).to be_empty
    end

    it 'returns instructor created activities first' do
      expect(presenter_with_instructor.activities).to eq(
        [
          visible_instructor_activity_1,
          hidden_instructor_activity_1,
          visible_activity_1,
          visible_activity_2,
          hidden_activity_1,
          hidden_activity_2
        ]
      )
    end
  end

  describe '#base_url' do
    it 'returns section toc url' do
      expect(presenter.base_url).to eq(instructor_assessments_path(program, {}))
    end

    it 'appends option to the url' do
      options = { all_units: true }
      expect(presenter.base_url(options)).to eq(
        instructor_assessments_path(program, options)
      )
    end
  end

  describe '#allow_assessment_randomization?' do
    context 'when the program does not allow assessment randomization' do
      before do
        allow(program).to receive(:allow_assessments_randomization?)
          .and_return(false)
      end

      it 'returns false' do
        expect(presenter.allow_assessment_randomization?(activity)).to be_falsey
      end
    end

    context 'when the program allows assessment randomization' do
      before do
        allow(program).to receive(:allow_assessments_randomization?)
          .and_return(true)
      end

      context 'when the activity is not randomizable' do
        let(:activity) { create(:activity, randomizable: false) }

        it 'returns false' do
          expect(presenter.allow_assessment_randomization?(activity)).to be_falsey
        end
      end

      context 'when the activity is randomizable' do
        let(:activity) { create(:activity, randomizable: true) }

        it 'returns true' do
          expect(presenter.allow_assessment_randomization?(activity)).to be_truthy
        end
      end
    end
  end

  describe '#school_has_shared_content' do
    it 'returns true if school has an Enterprise admin for program' do
      school = course.school
      admin = create(:institution_admin)
      create(:school_program_admin_user,
              user: admin,
              account_type: 'InstitutionAdmin',
              school: school,
              program: program)
      expect(presenter.show_shared_content_option).to be_truthy
    end

    it 'returns false if school has not an Enterprise admin for program' do
      expect(presenter.show_shared_content_option).to be_falsey
    end
  end

  describe '#randomize_per_student' do
    context 'when all assignments are randomized per student' do
      it 'returns true' do
        assignment_1 = instance_double(Assignment, randomize_per_student?: true)
        assignment_2 = instance_double(Assignment, randomize_per_student?: true)
        allow(presenter).to receive(:assignments_for_activity)
          .and_return([assignment_1, assignment_2])
        expect(presenter.randomize_per_student(activity)).to eq('Yes')
      end
    end

    context 'when some assessments are password protected' do
      it 'returns true' do
        assignment_1 = instance_double(Assignment, randomize_per_student?: true)
        assignment_2 = instance_double(Assignment, randomize_per_student?: false)
        allow(presenter).to receive(:assignments_for_activity)
          .and_return([assignment_1, assignment_2])
        expect(presenter.randomize_per_student(activity)).to eq('Varies')
      end
    end

    context 'when all assessments are not password protected' do
      it 'returns false' do
        assignment_1 = instance_double(Assignment, randomize_per_student?: false)
        assignment_2 = instance_double(Assignment, randomize_per_student?: false)
        allow(presenter).to receive(:assignments_for_activity)
          .and_return([assignment_1, assignment_2])
        expect(presenter.randomize_per_student(activity)).to eq('No')
      end
    end
  end

  describe '#show_google_classroom_button' do
    describe 'if Google Classroom configuration is Enabled for school and Enabled for course' do
      let(:school) { create(:school, share_to_google_classroom: true) }
      let(:course) do
        create(:course, program: program,
                        school: school,
                        share_to_google_classroom: true)
      end

      it 'returns true' do
        expect(presenter.show_google_classroom_button?).to be_truthy
      end
    end

    describe 'if Google Classroom configuration is Enabled for school and Disabled for course' do
      let(:school) { create(:school, share_to_google_classroom: true) }
      let(:course) do
        create(:course, program: program,
                        school: school,
                        share_to_google_classroom: false)
      end

      it 'returns false' do
        expect(presenter.show_google_classroom_button?).to be_falsey
      end
    end

    describe 'if Google Classroom configuration is Disabled for school and Enabled for course' do
      let(:school) { create(:school, share_to_google_classroom: false) }
      let(:course) do
        create(:course, program: program,
                        school: school,
                        share_to_google_classroom: true)
      end

      it 'returns false' do
        expect(presenter.show_google_classroom_button?).to be_falsey
      end
    end

    describe 'if Google Classroom configuration is Enabled for school and Enabled for course
      but no course is in focus' do
      let(:school) { create(:school, share_to_google_classroom: true) }
      let(:course) do
        create(:course, program: program,
                        school: school,
                        share_to_google_classroom: true)
      end
      let(:current_focus) { instance_double(Focus, sections: [], course: nil) }

      it 'returns false' do
        expect(presenter.show_google_classroom_button?).to be_falsey
      end
    end
  end
end
