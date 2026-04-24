describe Assignment, core: true do
  let(:activity) { build_stubbed(:activity) }
  let(:section) { build_stubbed(:section) }
  let(:assignment) do
    create(
      :assignment,
      assignable: activity,
      assignable_type: 'Activity',
      section: section
    )
  end

  describe 'validations' do
    it 'requires a category id' do
      bad_assignment = build(:assignment, category: nil)
      expect(bad_assignment).not_to be_valid
      expect(bad_assignment.errors[:category_id]).to contain_exactly('is required.')
    end

    context 'when instructor has set a specific release date for the assessment,' do
      let(:category) { create(:category, name: 'cat') }

      it 'requires release date to be a valid date_time' do
        bad_assignment = build(:assignment, show_assessment: 'a specific date and time')
        allow(bad_assignment.assignable).to receive(:strand_singular_label)
          .and_return(nil)
        expect(bad_assignment).not_to be_valid
        expect(bad_assignment.errors[:show_at]).to contain_exactly(
          'Release date is required.'
        )

        bad_assignment_2 = build(
          :assignment,
          category: category,
          show_assessment: 'a specific date and time',
          show_at: '02/32/2011 00:00:00'
        )
        allow(bad_assignment_2.assignable).to receive(:strand_singular_label)
          .and_return(nil)
        expect(bad_assignment_2).not_to be_valid
        expect(bad_assignment_2.errors[:show_at]).to contain_exactly(
          'You must specify a valid release date.'
        )
      end

      it 'should not allow the release date to be after due date time' do
        bad_assignment = build(:assignment, show_assessment: 'a specific date and time', show_at: '01/05/2012 10:00:00', due_date: '01/04/2012')
        allow(bad_assignment.assignable).to receive(:strand_singular_label).and_return(nil)
        expect(bad_assignment).not_to be_valid
      end

      it 'replaces #singular_label# with the correct label in the validation error message' do
        bad_assignment = build(
          :assignment,
          show_assessment: 'a specific date and time',
          show_at: '01/10/2012 10:00:00',
          due_date: '01/04/2012'
        )
        allow(bad_assignment.assignable).to receive(:strand_singular_label).and_return('questionnaire')
        bad_assignment.valid?
        messages = bad_assignment.errors.full_messages
        expect(messages).to include(' The questionnaire must be available before it is due.')
      end

      context 'when the release date is one the same day as the due date' do
        it 'should not allow the release date to be after the due date time' do
          bad_assignment = build_stubbed(
            :assignment,
            show_assessment: 'a specific date and time',
            show_at: '01/05/2012 10:00:00',
            due_date: '01/05/2012'
          )
          allow(bad_assignment).to receive(:due_date_time).and_return(Time.parse('01/05/2012 09:00:00'))
          allow(bad_assignment.assignable).to receive(:strand_singular_label).and_return(nil)
          expect(bad_assignment).not_to be_valid
          expect(bad_assignment.errors[:show_at]).to contain_exactly(
            'The assessment must be available before it is due.'
          )
        end
      end

      context 'when assignable is an activity' do
        it 'does not allow empty track_group' do
          activity = build_stubbed(:activity)
          bad_assignment = build(
            :assignment,
            assignable: activity,
            category: category,
            track_group_id: nil,
            vol_program: true
          )
          bad_assignment.valid?
          expect(bad_assignment.errors[:track_group_id]).to eq(['is required.'])
        end
      end

      context 'when assignable is not an activity' do
        it 'allows empty track group' do
          assignment = build(
            :assignment,
            assignable_type: 'ExternalActivity',
            category: category,
            vol_program: true,
            track_group_id: nil
          )
          assignment.valid?
          expect(assignment.errors[:track_group_id]).to be_blank
        end
      end
    end

    context 'when instructor has set a specific or due date for grade availability' do
      let(:category) { create(:category, name: 'cat') }

      it 'should be invalid if grade availability date is not a valid date_time' do
        bad_assignment = build(
          :assignment,
          category: category,
          grade_availability: 'on_specific_date'
        )
        allow(bad_assignment.assignable).to receive(:strand_singular_label).and_return(nil)
        expect(bad_assignment).not_to be_valid
        expect(bad_assignment.errors[:grades_available_at]).to contain_exactly(
          'Grade availability date is required.'
        )

        bad_assignment_2 = build(
          :assignment,
          category: category,
          grade_availability: 'on_specific_date',
          grades_available_at: '02/32/2011 00:00:00'
        )
        allow(bad_assignment_2.assignable).to receive(:strand_singular_label).and_return(nil)
        expect(bad_assignment_2).not_to be_valid
        expect(bad_assignment_2.errors[:grades_available_at]).to contain_exactly(
          'You must specify a valid result availability date.'
        )
      end

      context 'when grade availability is set to a specific date' do
        it 'should not allow the grade availability date to be before release date' do
          bad_assignment = build(:assignment, grade_availability: 'on_specific_date', show_at: '01/05/2012 10:00:00', grades_available_at: '01/05/2012')
          allow(bad_assignment.assignable).to receive(:strand_singular_label).and_return(nil)
          expect(bad_assignment).not_to be_valid
          expect(bad_assignment.errors[:grades_available_at]).to contain_exactly(
            'Results for this assessment can only be made available after it is released.'
          )
        end

        it 'replaces #singular_label# with the correct label in the validation error message' do
          bad_assignment = build(:assignment, grade_availability: 'on_specific_date', show_at: '01/10/2012 10:00:00', grades_available_at: '01/05/2012')
          allow(bad_assignment.assignable).to receive(:strand_singular_label).and_return('questionnaire')
          bad_assignment.valid?
          messages = bad_assignment.errors.full_messages
          expect(messages).to include(' Results for this questionnaire can only be made available after it is released.')
        end

        it 'does not allow the grade availability date to be nil' do
          assignment = build(:assignment, grade_availability: 'on_specific_date', show_at: '01/05/2012 10:00:00', grades_available_at: nil)
          allow(assignment.assignable).to receive(:strand_singular_label).and_return(nil)
          assignment.valid?
          messages = assignment.errors.full_messages
          expect(messages).to include(' Grade availability date is required.')
        end

        it 'should not allow the grade availability date to be before due date' do
          bad_assignment = FactoryBot.build_stubbed(:assignment,
                                                     grade_availability: 'on_specific_date',
                                                     show_assessment: 'a specific date and time',
                                                     show_at: '01/01/2012 07:00:00',
                                                     grades_available_at: '01/01/2012 8:00:00',
                                                     due_date: '01/05/2012')
          allow(bad_assignment).to receive(:due_date_time)
            .and_return(Time.zone.parse('01/05/2012 09:00:00'))
          allow(bad_assignment.assignable).to receive(:strand_singular_label).and_return(nil)
          expect(bad_assignment).to_not be_valid
          expect(bad_assignment.errors[:grades_available_at]).to contain_exactly(
            'Results for this assessment can only be made available after it is due.'
          )
        end

        it 'replaces #singular_label# with the correct label in the due date validation error message' do
          bad_assignment = FactoryBot.build_stubbed(:assignment,
                                                     grade_availability: 'on_specific_date',
                                                     show_assessment: 'a specific date and time',
                                                     show_at: '01/01/2012 07:00:00',
                                                     grades_available_at: '01/01/2012 8:00:00',
                                                     due_date: '01/05/2012')
          allow(bad_assignment).to receive(:due_date_time)
            .and_return(Time.zone.parse('01/05/2012 09:00:00'))
          allow(bad_assignment.assignable).to receive(:strand_singular_label).and_return('questionnaire')
          bad_assignment.valid?
          messages = bad_assignment.errors.full_messages
          expect(messages).to include(' Results for this questionnaire can only be made available after it is due.')
        end
     end
    end

    context 'when assigning to a category' do
      let(:category) { create(:category, name: 'cat') }

      it 'allows assessments to be assigned' do
        assessment = build_stubbed(:activity)
        allow(assessment).to receive(:assessment?).and_return(true)
        assignment = build(:assignment, assignable: assessment, category: category)
        expect(assignment).to be_valid
      end

      it 'allows activities that are not assessments to be assigned' do
        activity = build_stubbed(:activity)
        assignment = build(:assignment, assignable: activity, category: category)
        expect(assignment).to be_valid
      end
    end

    context 'when assigning to a credit_only category' do
      let(:credit_category) { create(:category, credit_only: true) }

      it 'allows assessment activities to be assigned' do
        assessment = build_stubbed(:activity)
        allow(assessment).to receive(:assessment?).and_return(true)
        assignment = build(:assignment, assignable: assessment, category: credit_category)
        expect(assignment).to be_valid
      end

      it 'allows activities that are not assessments to be assigned' do
        activity = build_stubbed(:activity)
        assignment = build(:assignment, assignable: activity, category: credit_category)
        expect(assignment).to be_valid
      end
    end
  end

  describe 'nested attributes' do
    let(:category) { create(:category) }

    it 'creates details when a time limit is set with no password' do
      assignment = build(
        :assignment,
        category: category,
        assigned_assessment_detail_attributes: {
          number_of_attempts: 1,
          time_limit: '2'
        }
      )
      assignment.save!
      expect(
        AssignedAssessmentDetail.find_by(assignment_id: assignment.id)
      ).not_to be_nil
    end

    it 'does not create details when a time limit is to zero with no password' do
      assignment = build(
        :assignment,
        category: category,
        assigned_assessment_detail_attributes: {
          number_of_attempts: 1,
          time_limit: '0'
        }
      )
      assignment.save!
      expect(
        AssignedAssessmentDetail.find_by(assignment_id: assignment.id)
      ).to be_nil
    end

    it 'does not create details when a password is set to blank with no time limit' do
      assignment = build(
        :assignment,
        category: category,
        assigned_assessment_detail_attributes: {
          number_of_attempts: 1,
          password: ''
        }
      )
      assignment.save!
      expect(
        AssignedAssessmentDetail.find_by(assignment_id: assignment.id)
      ).to be_nil
    end

    it 'creates details when a password is set with no time limit' do
      assignment = build(
        :assignment,
        category: category,
        assigned_assessment_detail_attributes: {
          number_of_attempts: 1,
          password: 'pasword'
        }
      )
      assignment.save!
      expect(
        AssignedAssessmentDetail.find_by(assignment_id: assignment.id)
      ).not_to be_nil
    end

    it 'does not create assessment details when set empty or nil' do
      assignment = build(
        :assignment,
        category: category,
        assigned_assessment_detail_attributes: {}
      )
      assignment.save!
      expect(
        AssignedAssessmentDetail.find_by(assignment_id: assignment.id)
      ).to be_nil

      assignment = build(:assignment, category: category)
      assignment.save!
      expect(
        AssignedAssessmentDetail.find_by(assignment_id: assignment.id)
      ).to be_nil
    end

    it 'creates details when number of attempts is > 1' do
      assignment = build(
        :assignment,
        category: category,
        assigned_assessment_detail_attributes: {
          number_of_attempts: '5'
        }
      )
      assignment.save!
      expect(
        AssignedAssessmentDetail.find_by(
          assignment_id: assignment.id
        ).number_of_attempts
      ).to eq(5)
    end

    it 'does not create assessment details if number of attempts is set to 1' do
      assignment = build(
        :assignment,
        category: category,
        assigned_assessment_detail_attributes: {
          number_of_attempts: '1'
        }
      )
      assignment.save!
      expect(
        AssignedAssessmentDetail.find_by(assignment_id: assignment.id)
      ).to be_nil
    end
  end

  describe 'scopes' do
    describe '.due_on' do
      it 'should return assignments when assignment exist on the due date passed' do
        assignment_1 = create(:assignment , due_date: 2.days.from_now.to_date)
        assignment_2 = create(:assignment , due_date: 3.days.from_now.to_date)
        expect(described_class.due_on(2.days.from_now.to_date)).to eq([assignment_1])
      end

      it 'should return [] when assignments dont exist on the due date passed' do
        assignment_1 = create(:assignment , due_date: 2.days.from_now.to_date)
        assignment_2 = create(:assignment , due_date: 5.days.ago.to_date)
        expect(described_class.due_on(1.days.from_now.to_date)).to eq([])
      end
    end

    describe '.due_on_week' do
      it 'returns assignments that are due between the given date and 6 days after' do
        assignment_1 = create(:assignment, due_date: Date.today)
        assignment_2 = create(:assignment, due_date: 6.days.from_now.to_date)
        create(:assignment, due_date: Date.yesterday)
        create(:assignment, due_date: 7.days.from_now)
        expect(described_class.due_on_week(Date.today)).to eq([assignment_1, assignment_2])
      end
    end

    describe '.by_category' do
      it 'returns the assignments in the specified category' do
        category_1 = build_stubbed(:category, id: 1)
        category_2 = build_stubbed(:category, id: 2)
        assignment_1 = create(:assignment, category: category_1)
        assignment_2 = create(:assignment, category: category_2)
        result = described_class.by_category(category_1)
        expect(result).to include(assignment_1)
        expect(result).not_to include(assignment_2)
      end
    end

    describe '.by_section' do
      before do
        @section_1 = build_stubbed(:section)
        @section_2 = build_stubbed(:section)
        @assignment_1 = create(:assignment, section: @section_1)
        @assignment_2 = create(:assignment, section: @section_2)
      end

      it 'returns all assignments for a specific section' do
        expect(described_class.by_section(@section_1)).to eq([@assignment_1])
      end

      it 'returns all assignments for all provided sections' do
        expect(described_class.by_section(@section_1, @section_2)).to eq([@assignment_1, @assignment_2])
      end
    end

    describe '.by_assignable_id' do
      before do
        @section_1 = build_stubbed(:section)
        @section_2 = build_stubbed(:section)
        @assignment_1 = create(:assignment, section: @section_1)
        @assignment_2 = create(:assignment, section: @section_2)
      end

      it 'returns all assignments for a specific assignable id' do
        expect(described_class.by_assignable_id(@assignment_1.assignable_id)).to eq([@assignment_1])
      end

      it 'returns all assignments for all provided assignable ids' do
        expect(described_class.by_assignable_id(@assignment_1.assignable_id, @assignment_2.assignable_id)).to eq([@assignment_1, @assignment_2])
      end
    end

    describe '.by_activities' do
      before do
        @activity = create(:activity)
        @assignment_1 = create(:assignment, :assignable => @activity)
      end

      it 'returns all assignments for a regular activity' do
        expect(described_class.by_activities(@activity)).to eq([@assignment_1])
      end

      it 'returns only the assignments for the specified section' do
        the_section = create(:section)
        other_section = create(:section)
        the_assignment = create(:assignment, section: the_section)
        other_assignment = create(:assignment, section: other_section)
        expect(described_class.by_section(the_section)).to eq([the_assignment])
      end
    end

    describe '.by_section_and_activity' do
      let(:activity_1) { create(:activity) }
      let(:activity_2) { create(:activity) }
      let(:section_1) { create(:section) }

      context 'with one activity, one section' do
        it 'returns their assignments' do
          assignment = create(:assignment, assignable: activity_1, section: section_1)
          expect(described_class.by_section_and_activity(section_1, activity_1)).to eq([assignment])
        end
      end

      context 'with multiple activities, one section' do
        it 'returns their assignments' do
          assignment_1 = create(:assignment, assignable: activity_1, section: section_1)
          assignment_2 = create(:assignment, assignable: activity_2, section: section_1)
          create(:assignment, assignable: activity_2, section: create(:section))
          expect(described_class.by_section_and_activity(section_1, activity_1, activity_2)).to eq([assignment_1, assignment_2])
        end
      end

      context 'with no matches' do
        it 'is empty array' do
          some_section = create(:section)
          assignment_1 = create(:assignment, assignable: activity_1, section: some_section)
          assignment_2 = create(:assignment, assignable: activity_2, section: some_section)
          expect(described_class.by_section_and_activity(section_1, activity_1)).to eq([])
        end
      end
    end

    describe '.by_activities_and_sections' do
      before do
        @activity = create(:activity)
        @section = create(:section)
        @assignment = create(:assignment, assignable: @activity, section: @section)
      end

      context 'with one activity, one section' do
        it 'returns their assignments' do
          expect(described_class.by_activities_and_sections(@activity, @section)).to eq([@assignment])
        end
      end

      context 'with one activity, multiple sections' do
        it 'returns their assignments' do
          expect(described_class.by_activities_and_sections(@activity, [@section])).to eq([@assignment])
        end
      end

      context 'with multiple activities, one section' do
        it 'returns their assignments' do
          expect(described_class.by_activities_and_sections([@activity], @section)).to eq([@assignment])
        end
      end

      context 'with multiple activities, multiple sections' do
        it 'returns their assignments' do
          expect(described_class.by_activities_and_sections([@activity], [@section])).to eq([@assignment])
        end
      end
    end

    describe '.non_practice_uncompleted' do
      it 'returns non-practice incomplete assignments', test_debt: true do
        skip
      end
    end

    describe '.released' do
      it 'returns released assignments' do
        Timecop.freeze(Time.now + 10.minutes) do
          released_assignment = create(:assignment, show_at: 5.minutes.ago)
          unreleased_assignment = create(:assignment, show_at: 15.minutes.from_now)
          expect(described_class.released).to eq([released_assignment])
        end
      end
    end

    describe '.in_unarchived_section' do
      before do
        assignable = create(:activity)
        archived_section = create(:section, is_archived: true)
        unarchived_section = create(:section)
        create(:assignment, assignable: assignable, section: archived_section)
        create(:assignment, assignable: assignable, section: unarchived_section)
      end

      it 'returns assignments in unarchived sections only' do
        expect(described_class.all.size).to eq(2)
        expect(described_class.in_unarchived_section.size).to eq(1)
      end
    end

    describe '.by_concept' do
      it 'returns assignments for activities in the given concept' do
        concept = create(:concept)
        activity = create(:activity, concept: concept)
        assignment = create(:assignment, assignable: activity)
        expect(described_class.by_concept(concept)).to eq([assignment])
      end
    end

    describe '.by_section_and_unit' do
      let(:unit_1) { create(:unit_with_lessons) }
      let(:unit_2) { create(:unit_with_lessons) }
      let(:section) { create(:section_with_course) }
      let(:activity_1) { create(:activity, lesson: unit_1.lessons.first) }
      let(:activity_2) { create(:activity, lesson: unit_2.lessons.first) }
      let!(:assignment_1) do
        create(:assignment, section: section, assignable: activity_1)
      end
      let!(:assignment_2) do
        create(:assignment, section: section, assignable: activity_2)
      end

      it 'returns the assignments of the given section with assignables on the given unit' do
        results = described_class.by_section_and_unit(section, unit_1)
        expect(results).to include assignment_1
        expect(results).not_to include assignment_2
      end

      it 'does not return the assignments that are not in the given section' do
        other_section_assignment = create(
          :assignment,
          section: create(:section_with_course),
          assignable: activity_1
        )
        results = described_class.by_section_and_unit(section, unit_1)
        expect(results).to include assignment_1
        expect(results).not_to include other_section_assignment
      end
    end

    describe '.by_type' do
      let(:activity) { create(:activity) }
      let(:section) { create(:section) }
      let!(:regular_activity_assignment) do
        create(:assignment, assignable: activity)
      end

      it 'does not return external activity assignments' do
        external_assignment = create(
          :assignment,
          due_date: Time.zone.today - 1,
          section: section,
          assignable: activity
        )

        # Use update column to allow simulating legacy data that
        # can no longer be created normally.
        external_assignment.update_column(:assignable_type, 'ExternalActivity')

        results = described_class.by_type('ExternalActivity')
        expect(results).not_to include external_assignment
      end

      it 'returns assignments for regular activities if param is Activity' do
        results = described_class.by_type(Activity)
        expect(results).to include regular_activity_assignment
      end
    end

    describe '.current' do
      it 'returns only current assignments' do
        current_assignment = create(:assignment, current: true)
        create(:assignment, current: false)
        described_class.current == [current_assignment]
      end
    end

    describe '.incomplete_by_user' do
      let(:section) { create(:section) }
      let(:user) { create(:user) }

      it 'should not return assignments of external activities' do
        assignment_1 = create(:assignment, section: section)
        external_assignment = create(:assignment, section: section)

        # Use update column to allow simulating legacy data that
        # can no longer be created normally.
        external_assignment.update_column(:assignable_type, 'ExternalActivity')

        assignments = described_class.incomplete_by_user(user)
        expect(assignments).to eq([assignment_1])
      end

      it 'returns incomplete assignments' do
        activity_1 = create(:activity)
        activity_2 = create(:activity)
        assignment_1 = create(
          :assignment,
          section: section,
          assignable: activity_1
        )
        assignment_2 = create(
          :assignment,
          section: section,
          assignable: activity_2
        )
        create(:attempt_completed, user: user, activity: activity_1, section: section)
        create(:attempt, user: user, activity: activity_2, section: section)
        assignments = described_class.incomplete_by_user(user)
        expect(assignments).to eq([assignment_2])
      end

      it 'returns incomplete assignments for one user' do
        user_2 = build_stubbed(:user)
        activity_1 = create(:activity)
        activity_2 = create(:activity)
        assignment_1 = create(:assignment, section: section, assignable: activity_1)
        assignment_2 = create(:assignment, section: section, assignable: activity_2)
        create(:attempt_completed, user: user_2, activity: activity_1, section: section)
        create(:attempt, user: user, activity: activity_2, section: section)
        assignments = described_class.incomplete_by_user(user)
        expect(assignments).to eq([assignment_1, assignment_2])
      end
    end
  end

  describe '.next_rank' do
    it 'calls next_rank method on a NextRankFinder class instance' do
      section = double(Section)
      activity = double(Activity)
      rank_finder = double(Assignment::NextRankFinder, next_rank: 1)
      expect(Assignment::NextRankFinder).to receive(:new).with(section, 'some_due_date', activity).and_return(rank_finder)
      expect(rank_finder).to receive(:next_rank)
      described_class.next_rank(section, 'some_due_date', activity)
    end
  end

  describe '.by_activity_list_completed_and_released' do
    it 'returns assignments for the specified activities that have ' \
       'completed attempts matching specified user and section' do
      activity = create(:activity)
      user = create(:user)
      section = create(:section)
      assignment = create(:assignment, assignable: activity, section: section, show_at: 1.day.ago)
      create(:attempt_completed, activity: activity, section: section, user: user)

      expect(
        described_class.by_activity_list_completed_and_released(
          [activity], user, section
        )
      ).to include assignment
    end
  end

  describe '.unique_due_dates_by_section_and_category' do
    let(:category) { create(:category) }
    let(:section_1) { create(:section) }
    let(:section_2) { create(:section) }
    let(:section_ids) { [section_1.id, section_2.id] }
    let(:due_date_1) { section.course.start_date + 30.days }
    let(:due_date_2) { due_date_1 + 1.day }
    let(:due_date_3) { due_date_1 + 2.days }

    before do
      create(
        :assignment, section: section_1, category: category, due_date: due_date_1
      )
      # same due date as first assignment
      create(
        :assignment, section: section_1, category: category, due_date: due_date_1
      )
      create(
        :assignment, section: section_2, category: category, due_date: due_date_2
      )
      other_category = create(:category)
      create(
        :assignment, section: section_2, category: other_category, due_date: due_date_3
      )
    end

    it 'returns unique assignment due dates in all specified sections ' \
       'matching the specified category' do
      expect(
        described_class.unique_due_dates_by_section_and_category(
          section_ids, category.id
        ).pluck(:due_date)
      ).to eq([due_date_1, due_date_2])
    end

    it 'returns unique assignment due dates in all categories in all ' \
       'specified sections when no category is specified' do
      expect(
        described_class.unique_due_dates_by_section_and_category(
          section_ids, nil
        ).pluck(:due_date)
      ).to eq([due_date_1, due_date_2, due_date_3])
    end

    it 'returns unique assignment due dates for a single section' do
      expect(
        described_class.unique_due_dates_by_section_and_category(
          [section_1.id], category.id
        ).pluck(:due_date)
      ).to eq([due_date_1])
    end

    it 'returns unique assignment due dates for a single section with no ' \
       'category specified' do
      expect(
        described_class.unique_due_dates_by_section_and_category(
          [section_1.id], nil
        ).pluck(:due_date)
      ).to eq([due_date_1])
    end

    it 'generates a query with a DISTINCT keyword' do
      expect(
        described_class.unique_due_dates_by_section_and_category(
          section_ids, category.id
        ).to_sql
      ).to match('DISTINCT')
    end
  end

  describe '#timed?' do
    let(:student) { build_stubbed(:student) }

    before do
      assignment.assigned_assessment_detail = AssignedAssessmentDetail.new
    end

    context 'when the time limit is nil' do
      it 'returns false' do
        allow(assignment.assigned_assessment_detail).to receive(:time_limit).and_return(nil)
        expect(assignment.timed?(student)).to be_falsey
      end
    end

    context 'when the time limit is 0' do
      it 'returns false' do
        allow(assignment.assigned_assessment_detail).to receive(:time_limit).and_return(0)
        expect(assignment.timed?(student)).to be_falsey
      end
    end

    context 'when the time limit is > 0' do
      it 'returns true' do
        allow(assignment.assigned_assessment_detail).to receive(:time_limit).and_return(1)
        expect(assignment.timed?(student)).to be_truthy
      end
    end
  end

  describe '#late?' do
    let(:section_due_time) { '10:00 PM' }
    let(:user_time_zone) { 'Eastern Time (US & Canada)' }
    let(:due_date) { section.course.start_date + 30.days }
    let(:section) { create(:section, time_zone: section_time_zone, due_time: section_due_time) }
    let(:assignment) { create(:assignment, due_date: due_date, section: section) }

    context "when section time_zone is different than the current user's" do
      let(:section_time_zone) { 'Pacific Time (US & Canada)' }

      it 'is true if submitted 1 minute later than the due date and time' do
        Time.use_zone(user_time_zone) do
          # 10 pm Pacific time is 1 am on the next day in Eastern time
          submitted_at = Time.zone.parse("#{due_date + 1.day} 01:01 AM")
          expect(assignment).to be_late(submitted_at)
        end
      end

      it 'is true if submitted 1 day later than the due date and time' do
        Time.use_zone(user_time_zone) do
          # 10 pm Pacific time is 1 am on the next day in Eastern time
          submitted_at = Time.zone.parse("#{due_date + 2.days} 01:00 AM")
          expect(assignment).to be_late(submitted_at)
        end
      end

      it 'is false if submitted 1 minute before the due date and time' do
        Time.use_zone(user_time_zone) do
          # 10 pm Pacific time is 1 am on the next day in Eastern time
          submitted_at = Time.zone.parse("#{due_date + 1.day} 12:59 AM")
          expect(assignment).not_to be_late(submitted_at)
        end
      end

      it 'is false if submitted 1 day before the due date and time' do
        Time.use_zone(user_time_zone) do
          submitted_at = Time.zone.parse("#{due_date} 01:00 AM")
          expect(assignment).not_to be_late(submitted_at)
        end
      end

      it 'is false if submitted at exactly the due date and time' do
        Time.use_zone(user_time_zone) do
          submitted_at = Time.zone.parse("#{due_date + 1} 01:00 AM")
          expect(assignment).not_to be_late(submitted_at)
        end
      end

      it 'is false if submitted_at is nil' do
        expect(assignment).not_to be_late(nil)
      end
    end

    context "when section time_zone is the same as the current user's" do
      let(:section_time_zone) { 'Eastern Time (US & Canada)' }

      it 'is true if submitted 1 minute later than the due date and time' do
        Time.use_zone(user_time_zone) do
          submitted_at = Time.zone.parse("#{due_date} 10:01 PM")
          expect(assignment).to be_late(submitted_at)
        end
      end

      it 'is true if submitted 1 day later than the due date and time' do
        Time.use_zone(user_time_zone) do
          submitted_at = Time.zone.parse("#{due_date + 1.day} 12:00 AM")
          expect(assignment).to be_late(submitted_at)
        end
      end

      it 'is false if submitted 1 minute before the due date and time' do
        Time.use_zone(user_time_zone) do
          submitted_at = Time.zone.parse("#{due_date} 09:59 PM")
          expect(assignment).not_to be_late(submitted_at)
        end
      end

      it 'is false if submitted 1 day before the due date and time' do
        Time.use_zone(user_time_zone) do
          submitted_at = Time.zone.parse("#{due_date - 1.day} 10:00 PM")
          expect(assignment).not_to be_late(submitted_at)
        end
      end

      it 'is false if submitted at exactly the due date and time' do
        Time.use_zone(user_time_zone) do
          submitted_at = Time.zone.parse("#{due_date} 10:00 PM")
          expect(assignment).not_to be_late(submitted_at)
        end
      end
    end

    context 'when assignment has a custom due_time' do
      let(:custom_due_time) { '5:00 PM' }
      let(:section) { create(:section, due_time: section_due_time) }

      before do
        assignment.custom_due_time = custom_due_time
      end

      it 'is true if submitted 1 minute later than the custom due time' do
        Time.use_zone(section.time_zone) do
          submitted_at = Time.zone.parse("#{due_date} 05:01 PM")
          expect(assignment).to be_late(submitted_at)
        end
      end

      it 'is false if submitted 1 minute before the custom due time' do # test_debt: true do
        # skip 'Fails intermittently, fix in MAE-31525'
        Time.use_zone(section.time_zone) do
          submitted_at = Time.zone.parse("#{due_date} 04:59 PM")
          expect(assignment).not_to be_late(submitted_at)
        end
      end

      it 'is false if submitted at exactly the custom due time' do # test_debt: true do
        # skip 'Fails intermittently, fix in MAE-31525'
        Time.use_zone(section.time_zone) do
          submitted_at = Time.zone.parse("#{due_date} 05:00 PM")
          expect(assignment).not_to be_late(submitted_at)
        end
      end

      it 'is false if submitted 1 day before the due date and custom due time' do
        Time.use_zone(section.time_zone) do
          submitted_at = Time.zone.parse("#{due_date - 1.day} 05:00 PM")
          expect(assignment).not_to be_late(submitted_at)
        end
      end

      it 'is true if submitted 1 day later than the due date and time' do
        Time.use_zone(section.time_zone) do
          submitted_at = Time.zone.parse("#{due_date + 1.day} 05:00 PM")
          expect(assignment).to be_late(submitted_at)
        end
      end
    end
  end

  describe '#due_time_zone' do
    # Create a course that spans an entire year.
    let(:year) { Time.current.year }
    let(:course) do
      create(
        :course,
        start_date: Date.civil(year, 1, 1),
        end_date: Date.civil(year + 1, 1, 1)
      )
    end
    let(:section) do
      create(:section, course: course, time_zone: 'Central Time (US & Canada)')
    end

    context 'with an assignment due during daylight savings,' do
      it 'returns the time zone abbreviation for daylight time' do
        due_date = Date.civil(year, 7, 1)
        assignment = create(:assignment, due_date: due_date, section: section)
        expect(assignment.due_time_zone).to eq('CDT')
      end
    end

    context 'with an assignment due outside of daylight savings,' do
      it 'returns the time zone abbreviation for standard time' do
        due_date = Date.civil(year, 1, 2)
        assignment = create(:assignment, due_date: due_date, section: section)
        expect(assignment.due_time_zone).to eq('CST')
      end
    end

    context "when the user's current time zone is different than the section time zone" do
      it 'returns the abbreviation for the section time zone' do
        user_time_zone = 'Samoa'
        Time.use_zone(user_time_zone) do
          due_date = Date.civil(year, 1, 1)
          assignment = create(:assignment, due_date: due_date, section: section)
          expect(assignment.due_time_zone).to eq('CST')
        end
      end
    end
  end

  describe '#due_date_in_future?' do
    let(:due_time) { '10:00 AM' }
    let(:server_timezone) { 'Eastern Time (US & Canada)' }

    context 'with a section in the same time zone as the server,' do
      let(:section_timezone) { 'Eastern Time (US & Canada)' }
      let(:section) do
        build_stubbed(:section, due_time: due_time, time_zone: section_timezone)
      end

      it 'is true when due_date is a future day' do
        Time.use_zone(server_timezone) do
          Timecop.travel(Time.zone.local(2012, 2, 8, 9, 59)) do
            assignment = build_stubbed(
              :assignment, due_date: 1.day.from_now.to_date, section: section
            )
            expect(assignment).to be_due_date_in_future
          end
        end
      end

      it 'is true when the due_date is the same day at a future time' do
        Time.use_zone(server_timezone) do
          Timecop.travel(Time.zone.local(2012, 2, 8, 9, 59)) do
            assignment = build_stubbed(
              :assignment, due_date: 0.days.from_now.to_date, section: section
            )
            expect(assignment).to be_due_date_in_future
          end
        end
      end

      it 'is false when the due_date is in the past' do
        Time.use_zone(server_timezone) do
          Timecop.travel(Time.zone.local(2012, 2, 8, 10, 1)) do
            assignment = build_stubbed(
              :assignment, due_date: 1.day.ago.to_date, section: section
            )
            expect(assignment).not_to be_due_date_in_future
          end
        end
      end

      it 'is false when the due_date is the same day at an earlier time' do
        Time.use_zone(server_timezone) do
          Timecop.travel(Time.zone.local(2012, 2, 8, 10, 1)) do
            assignment = build_stubbed(
              :assignment, due_date: 0.days.ago.to_date, section: section
            )
            expect(assignment).not_to be_due_date_in_future
          end
        end
      end
    end

    context 'with a section in a different time zone from the server' do
      let(:section_timezone) { 'Pacific Time (US & Canada)' }
      let(:section) do
        build_stubbed(:section, due_time: due_time, time_zone: section_timezone)
      end

      it 'is true when due_date is a future day' do
        Time.use_zone(server_timezone) do
          Timecop.travel(Time.zone.local(2012, 2, 8, 12, 59)) do
            assignment = build_stubbed(
              :assignment, due_date: 1.day.from_now.to_date, section: section
            )
            expect(assignment).to be_due_date_in_future
          end
        end
      end

      it 'is true when the due_date is the same day at a future time' do
        Time.use_zone(server_timezone) do
          Timecop.travel(Time.zone.local(2012, 2, 8, 12, 59)) do
            assignment = build_stubbed(
              :assignment, due_date: 0.days.from_now.to_date, section: section
            )
            expect(assignment).to be_due_date_in_future
          end
        end
      end

      it 'is false when the due_date is a past day' do
        Time.use_zone(server_timezone) do
          Timecop.travel(Time.zone.local(2012, 2, 8, 13, 1)) do
            assignment = build_stubbed(
              :assignment, due_date: 1.day.ago.to_date, section: section
            )
            expect(assignment).not_to be_due_date_in_future
          end
        end
      end

      it 'it is false when the due_date is the same day at a past time' do
        Time.use_zone(server_timezone) do
          Timecop.travel(Time.zone.local(2012, 2, 8, 13, 1)) do
            assignment = build_stubbed(
              :assignment, due_date: 0.days.ago.to_date, section: section
            )
            expect(assignment).not_to be_due_date_in_future
          end
        end
      end
    end
  end

  describe '#max_attempts' do
    let(:category) { create(:category, name: 'cat', max_attempts: 2) }

    it 'returns category max number of attempts' do
      allow(assignment).to receive(:assessment?).and_return(true)
      allow(assignment).to receive(:category).and_return(category)

      expect(assignment.max_attempts).to eq(2)
    end
  end

  describe '#all_sections_in_course' do
    it 'returns all sections in course' do
      course = create(:course)
      section_1 = create(:section, course: course)
      section_2 = create(:section, course: course)
      assignment = create(:assignment, section: section_1)
      assignment.reload
      expect(assignment.all_sections_in_course).to include(section_1)
      expect(assignment.all_sections_in_course).to include(section_2)
    end
  end

  describe '#sections_in_course_count' do
    it 'returns the sections count' do
      assignment = build_stubbed(:assignment)
      expect(assignment).to receive(:all_sections_in_course).and_return(['section'])
      expect(assignment.sections_in_course_count).to eq(1)
    end
  end

  describe '#credit_only?' do
    it 'returns the associated category credit_only setting' do
      assignment = build_stubbed(:assignment)
      category = build_stubbed(:category)
      expect(assignment).to receive(:category).and_return(category)
      expect(assignment.credit_only?).to eq(category.credit_only)
    end
  end

  describe '#due_date_released?' do
    let(:section_1) { create(:section, days_to_show_assignment_due_date: 5) }
    let(:future_released_assignment) { create(:assignment, section: section_1) }
    let(:future_unreleased_assignment) { create(:assignment, section: section_1) }

    it 'returns true if no value is set for days to show assignment due dates' do
      assignment = build_stubbed(:assignment)
      expect(assignment.due_date_released?).to be true
    end

    it 'returns true for an assignment in the future that should be released' do
      # As doing future_unreleased_assignment.due_date_time - 5.days can add an offset
      # depending on the timezone. We need to call .to_date to avoid that offset
      # when we freeze the time 5.days ago as it is time zone agnostic.
      Timecop.freeze((future_released_assignment.due_date_time - 5.days).to_date) do
        expect(future_released_assignment.due_date_released?).to be true
      end
    end

    it 'returns false if due dates are not released' do
      # As doing future_unreleased_assignment.due_date_time - 6.days can add an offset
      # depending on the timezone. We need to call .to_date to avoid that offset
      # when we freeze the time 6.days ago as it is time zone agnostic.
      Timecop.freeze((future_unreleased_assignment.due_date_time - 6.days).to_date) do
        expect(future_unreleased_assignment.due_date_released?).to be false
      end
    end
  end

  describe '#assessments_for_section' do
    let(:section_1) { build_stubbed(:section) }
    let(:section_2) { build_stubbed(:section) }
    let!(:current_assignment) { create(:assignment, section: section_1, current: true) }
    let!(:current_assessment_assignment) { create(:assignment, section: section_1, current: true, show_assessment: 'I release it') }
    let!(:other_assessment_assignment) { create(:assignment, section: section_2, current: false, show_assessment: 'I release it') }

    it 'returns assessment assignments' do
      expect(described_class.assessments_for_section(section_1)).to eq([current_assessment_assignment])
    end

    it 'accepts more than one section as a parameter' do
      expect(described_class.assessments_for_section([section_1, section_2])).to eq([current_assessment_assignment, other_assessment_assignment])
    end
  end

  describe '#grade_availability' do
    it 'should return :on_grading by default if grade_availability db field is null' do
      assignment = create(:assignment, grade_availability: nil)
      expect(assignment.grade_availability).to be :on_grading
    end

    it 'should return grade_availability db field value mapped as a symbol' do
      assignment = create(:assignment, grade_availability: 'some value')
      expect(assignment.grade_availability).to eq('some value'.to_sym)
    end
  end

  describe '#assessment_grade_available?', test_debt: true do
    it "is false if grade_availability is not set and section has students that didn't complete the assignment" do
      section = create(:section)
      student = create(:student)
      student.sections << section
      assignment = create(:assignment, section: section, grade_availability: nil)
      expect(assignment.assessment_grade_available?).to be_falsey
    end

    it "is true if grade_availability is not set and section doesn't have students" do
      section = create(:section)
      assignment = create(:assignment, section: section, grade_availability: nil)
      expect(assignment.assessment_grade_available?).to be_truthy
    end

    it "is false when grade_availabilty is 'Never'," do
      assignment = create(:assignment, grade_availability: 'never')
      expect(assignment.assessment_grade_available?).to be_falsey
    end

    context "when grade_availability is 'After I grade'," do
      before do
        @section = create(:section)
        @student_1 = create(:student)
        @student_2 = create(:student)
        @student_1.sections << @section
        @student_2.sections << @section
        @activity = create(:activity)

        @assignment = create(:assignment, assignable: @activity, section: @section, grade_availability: 'on_grading')
      end

      it 'is true if all student submissions for the section have been graded' do
        allow(@assignment).to receive(:score_actions) do
          [double(GradebookEngine::ScoreAction, pending?: false),
           double(GradebookEngine::ScoreAction, pending?: false)]
        end
        expect(@assignment.assessment_grade_available?).to be_truthy
      end

      it 'is false if no student submissions for the section have been graded' do
        allow(@assignment).to receive(:score_actions) do
          [double(GradebookEngine::ScoreAction, pending?: true),
           double(GradebookEngine::ScoreAction, pending?: true)]
        end
        expect(@assignment.assessment_grade_available?).to be_falsey
      end

      it 'is false if some students have been graded and others have not' do
        allow(@assignment).to receive(:score_actions) do
          [double(GradebookEngine::ScoreAction, pending?: true),
           double(GradebookEngine::ScoreAction, pending?: false)]
        end
        expect(@assignment.assessment_grade_available?).to be_falsey
      end

      it 'is false if some students have not submitted the assessment' do
        allow(@assignment).to receive(:score_actions) do
          [double(GradebookEngine::ScoreAction, pending?: true)]
        end
        expect(@assignment.assessment_grade_available?).to be_falsey
      end

      context 'when the assignment is past due' do
        before { @assignment.update! due_date: Date.yesterday }

        it 'returns true if number of graded scores equals the number of submitted scores' do
          allow(@assignment).to receive(:score_actions) do
            [double(GradebookEngine::ScoreAction, pending?: false,
                                                  submitted_at: Date.yesterday),
             double(GradebookEngine::ScoreAction, pending?: false,
                                                  submitted_at: Date.yesterday)]
          end
          expect(@assignment).to be_assessment_grade_available
        end

        it 'returns false if the number of grades scores does not equal the number of submitted scores' do
          allow(@assignment).to receive(:score_actions) do
            [double(GradebookEngine::ScoreAction, pending?: false,
                                                  submitted_at: Date.yesterday),
             double(GradebookEngine::ScoreAction, pending?: true,
                                                  submitted_at: Date.yesterday)]
          end
          expect(@assignment).not_to be_assessment_grade_available
        end

        context 'given at least one student in the section has not completed the assessment' do
          before do
            @student_3 = create(:student)
            @student_3.sections << @section
          end

          it 'returns true if number of graded scores equals the number of submitted scores' do
            allow(@assignment).to receive(:score_actions) do
              [double(GradebookEngine::ScoreAction, pending?: false,
                                                    submitted_at: Date.yesterday),
               double(GradebookEngine::ScoreAction, pending?: false,
                                                    submitted_at: Date.yesterday),
               double(GradebookEngine::ScoreAction, pending?: true,
                                                    submitted_at: nil)]
            end
            expect(@assignment).to be_assessment_grade_available
          end
        end
      end
    end

    context "when grade_availability is 'After the due time'," do
      it 'is true if the due date and time have passed' do
        section = create(:section, due_time: '23:59:59')
        assignment = create(:assignment, section: section, grade_availability: 'on_due_date',
                                         due_date: 1.day.ago.to_date)
        expect(assignment.assessment_grade_available?).to be_truthy
      end

      it 'is false if the due date is today but the due time is in the future' do
        #todo: rework this to use timecop instad
        section = create(:section, due_time: '23:59:59')
        assignment = create(:assignment, section: section, grade_availability: 'on_due_date',
                                         due_date: Date.today)
        expect(assignment.assessment_grade_available?).to be_falsey
      end

      it 'is false if the due date is after today' do
        section = create(:section)
        assignment = create(:assignment, section: section, grade_availability: 'on_due_date',
                                         due_date: 2.days.from_now)
        expect(assignment.assessment_grade_available?).to be_falsey
      end
    end

    context "when grade_availability is 'After a specific date and time'," do
      it 'is true if the grades_available_at date and time have passed' do
        activity = FactoryBot.build_stubbed(:activity)
        assignment = FactoryBot.build_stubbed(:assignment,
                                               grade_availability: 'on_specific_date',
                                               grades_available_at: 1.day.ago,
                                               show_at: 3.days.ago,
                                               assignable: activity)
        allow(activity).to receive(:strand_singular_label).and_return('contextos')
        expect(assignment.assessment_grade_available?).to be_truthy
      end

      it 'is false if the grades_available_at date is today but the specified time is in the future' do
        activity = FactoryBot.build_stubbed(:activity)
        assignment = FactoryBot.build_stubbed(:assignment,
                                               grade_availability: 'on_specific_date',
                                               grades_available_at: 1.hour.from_now,
                                               show_at: 3.days.ago,
                                               assignable: activity)
        allow(activity).to receive(:strand_singular_label).and_return('contextos')
        expect(assignment.assessment_grade_available?).to be_falsey
      end

      it 'is false if the grades_available_at date is after today' do
        activity = FactoryBot.build_stubbed(:activity)
        assignment = FactoryBot.build_stubbed(:assignment,
                                               grade_availability: 'on_specific_date',
                                               grades_available_at: 1.day.from_now,
                                               show_at: 3.days.ago,
                                               assignable: activity)
        allow(activity).to receive(:strand_singular_label).and_return('contextos')
        expect(assignment.assessment_grade_available?).to be_falsey
      end
    end

    context "when grade_availability is 'When I release it'," do
      it 'is true if the grades_available_at date and time have passed' do
        assignment = create(:assignment, grade_availability: 'on_release', grades_available_at: 1.day.ago)
        expect(assignment.assessment_grade_available?).to be_truthy
      end

      it 'is false if the grades_available_at date and time is not set' do
        assignment = create(:assignment, grade_availability: 'on_release', grades_available_at: nil)
        expect(assignment.assessment_grade_available?).to be_falsey
      end

      it 'is false if the grades_available_at date is today but the specified time is in the future' do
        assignment = create(:assignment, grade_availability: 'on_release', grades_available_at: 1.hour.from_now)
        expect(assignment.assessment_grade_available?).to be_falsey
      end

      it 'is false if the grades_available_at date is after today' do
        assignment = create(:assignment, grade_availability: 'on_release', grades_available_at: 1.day.from_now)
        expect(assignment.assessment_grade_available?).to be_falsey
      end
    end
  end

  describe '.activity_assignments' do
    let(:activity) { create(:activity) }
    let(:section) { create(:section) }
    let(:user) { create(:user) }
    let(:yesterday) { Time.zone.today - 1 }

    it 'includes only assigned internal activities' do
      non_internal_activity = create(:activity)
      external_assignment = create(
        :assignment,
        due_date: yesterday,
        section: section,
        assignable: non_internal_activity
      )

      # Use update column to allow simulating legacy data that
      # can no longer be created normally.
      external_assignment.update_column(:assignable_type, 'ExternalActivity')

      assignment = create(
        :assignment,
        due_date: yesterday,
        section: section,
        assignable: activity
      )
      activity_assignments = described_class.activity_assignments(
        section, [activity, non_internal_activity]
      )
      expect(activity_assignments).to include assignment
      expect(activity_assignments).not_to include external_assignment
    end

    it 'does not include unassigned activities' do
      activity_assignments = described_class.activity_assignments(
        section, [activity]
      )
      expect(activity_assignments).to be_empty
    end

    context 'when passed a category id,' do
      it 'only finds assignments within the specified category' do
        category_1 = create(:category)
        category_2 = create(:category)
        assignment = create(
          :assignment,
          assignable: activity,
          category: category_1,
          due_date: yesterday,
          section: section
        )

        activity_2 = create(:activity)
        create(
          :assignment,
          assignable: activity_2,
          category: category_2,
          due_date: yesterday,
          section: section
        )

        activity_assignments = described_class.activity_assignments(
          section,
          [activity, activity_2],
          category_1.id
        )
        expect(activity_assignments).to contain_exactly(assignment)
      end
    end

    context 'when passed multiple sections,' do
      it 'returns activities assigned in all sections' do
        assignment_1 = create(
          :assignment,
          assignable: activity,
          due_date: yesterday,
          section: section
        )

        other_section = create(:section)
        activity_2 = create(:activity)
        assignment_2 = create(
          :assignment,
          assignable: activity_2,
          due_date: yesterday,
          section: other_section
        )
        activity_assignments = described_class.activity_assignments(
          [section, other_section],
          [activity, activity_2]
        )
        expect(activity_assignments).to contain_exactly(assignment_1, assignment_2)
      end
    end
  end

  describe '.find_by_sections_and_category' do
    before do
      @user = create(:user)
      @category = build_stubbed(:category, name: 'Flat')
      @section_1 = build_stubbed(:section)
      @section_2 = build_stubbed(:section)

      @activities = []
      4.times.each { @activities << build_stubbed(:activity) }

      @assignments = []
      @activities.each_with_index do |activity, index|
        @assignments << create(:assignment, assignable: activity,
                                            due_date: index.days.from_now,
                                            section: @section_1,
                                            category: @category,
                                            current: (index == 0))
      end
      @assignments << create(:assignment, assignable: build_stubbed(:activity),
                                          due_date: Date.yesterday,
                                          section: @section_2,
                                          category: @category,
                                          current: true)
    end

    it 'returns assignments for a category sorted by due date' do
      results = described_class.find_by_sections_and_category([@section_1, @section_2], @category.id)
      expect(results).to eq([@assignments[4]] + @assignments[0..3])
    end

    it 'filters assignments by section' do
      expect(described_class.find_by_sections_and_category([@section_1], @category.id)).to eq(@assignments[0..3])
      expect(described_class.find_by_sections_and_category([@section_2], @category.id)).to eq([@assignments[4]])
    end
  end

  describe '.create_assignment_calendar' do
    before do
      @user = create(:user)
      @section = create(:section)
    end

    it 'should return an assignment_assignment calendar class' do
      calendar = described_class.create_assignment_calendar(@section, @user, Date.today, Date.today)
      expect(calendar).to be_an(AssignmentCalendar)
    end

    it 'should have an assignment in it' do
      @assigned = create(:activity)
      @unassigned = create(:activity)
      @assigned_date = Date.today
      @assignment = create(:assignment, section: @section, assignable: @assigned, due_date: @assigned_date)
      calendar = described_class.create_assignment_calendar(@section, @user, Date.today, Date.today)
      assignment_count = 0
      calendar.each do |day|
        assignment_count += day.assignments.count
      end
      expect(assignment_count).to eq(1)
    end
  end

  describe '.find_with_course_category' do
    it 'should return the assignment matching specified params' do
      section = create(:section)
      activity = build_stubbed(:activity)
      course_cat = create(:category)
      assignment = create(:assignment, section: section, assignable: activity, category: course_cat)
      expect(described_class.find_with_course_category(section, activity)).to eq(assignment)
    end


    it 'should return nil without searching for assignment if passed a nil section' do
      activity = build_stubbed(:activity)
      expect(described_class).not_to receive(:first)
      expect(described_class.find_with_course_category(nil, activity)).to be_nil
    end

    it 'should return nil if no assignment is found for the specified params' do
      activity = build_stubbed(:activity)
      section = create(:section)
      expect(described_class.find_with_course_category(section, activity)).to be_nil
    end
  end

  describe '#update_availability' do
    context 'when assessment availability is to be updated' do
      it 'should set to nil shown_at attribute if it has a date set' do
        assignment = create(:assignment, show_at: Time.now)
        assignment.update_availability 'assessment_release'
        expect(assignment.show_at).to be_nil
      end

      it 'should set to current date and time shown_at attribute if it has no value' do
        current_date = Time.now
        assignment = create(:assignment, show_at: nil)
        assignment.update_availability 'assessment_release'
        expect(assignment.show_at.to_date).to eq(current_date.to_date)
      end
    end

    context 'when assessment grade availability is to be updated' do
      it 'should set to nil grades_available_at attribute if it has a date set' do
        assignment = create(:assignment, grades_available_at: Time.now)
        assignment.update_availability 'grade_release'
        expect(assignment.grades_available_at).to be_nil
      end

      it 'should set to current date and time grades_available_at attribute if it has no value' do
        current_date = Time.now
        assignment = create(:assignment, grades_available_at: nil)
        assignment.update_availability 'grade_release'
        expect(assignment.grades_available_at.to_date).to eq(current_date.to_date)
      end
    end
  end

  describe '.create_assignment_set_activity' do
    let(:activity_1) { create(:activity) }
    let(:activity_2) { create(:activity) }
    let(:activity_3) { create(:activity) }
    let(:activity_4) { create(:activity) }
    let(:category) { create(:category) }
    let(:due_date) { Time.zone.today + 1.day }
    let(:section) { create(:section) }

    context 'when there are manually ordered assignments for the same section and due date' do
      let(:new_assignment) do
        described_class.new(
          assignable: activity_3,
          category: category,
          due_date: due_date,
          section: section
        )
      end

      before do
        create(:assignment, assignable: activity_1, section: section, due_date: due_date)
        create(:assignment, assignable: activity_2, section: section, due_date: due_date)
        assignment_set = create(
          :assignment_set,
          section: section,
          due_date: due_date
        )
        create(
          :assignment_set_activity,
          activity: activity_1,
          assignment_set: assignment_set,
          assignment_set_rank: 1
        )
        create(
          :assignment_set_activity,
          activity: activity_2,
          assignment_set: assignment_set,
          assignment_set_rank: 2
        )
      end

      it 'creates assignment set activity record for the new assignment' do
        expect do
          new_assignment.create_assignment_set_activity
        end.to change(AssignmentSetActivity, :count).from(2).to(3)
      end

      it 'does not error when there are no assignment set activities' do
        assignment_set = AssignmentSet.find_by(due_date: due_date, section_id: section.id)
        assignment_set.activities.delete_all
        expect do
          new_assignment.create_assignment_set_activity
        end.not_to raise_error
      end
    end

    context 'when there are not manually ordered assignments for the same section and due date' do
      it 'does not create an assignment set activity record for the new assignment' do
        new_assignment = described_class.new(
          assignable: activity_4,
          category: category,
          due_date: due_date,
          section: section
        )

        expect do
          new_assignment.create_assignment_set_activity
        end.not_to change(AssignmentSetActivity, :count)
      end
    end
  end

  describe '#destroy' do
    before do
      school = build_stubbed(:school)
      program = build_stubbed(:program)
      instructor = build_stubbed(:instructor)
      course = create(:course, school: school, program: program, owner: instructor)
      @section = create(:section, course: course, instructor: instructor)
      @assignment = create(:assignment, section: @section)
      @assignment.save!
    end

    it 'should destroy the assignment' do
      @assignment.destroy
      expect(described_class.all).to eq([])
    end

    it 'should notify the gradebook of the assignment deletion' do
      expect(@assignment).to receive(:notify_deletion)
      @assignment.destroy
      expect(described_class.all).to eq([])
    end

    it 'should destroy group chat config of the corresponding assignment' do
      @group_chat_activity = create(:activity, activity_type: 'group_chat')
      @group_chat_assignment = create(
        :assignment,
        assignable: @group_chat_activity,
        section: @section,
      )
      @group_chat_assignment_config = create(
        :group_chat_assignment_config,
        assignment: @group_chat_assignment
      )
      @group_chat_assignment.destroy

      expect(described_class.all).not_to include(@group_chat_assignment)
      expect(GroupChatAssignmentConfig.find_by_id(@group_chat_assignment_config.id)).to be_nil
    end

    it 'does not throw any error if external activity assignment is destroyed' do
      category = create(:category, name: 'cat')
      assignment = build(
        :assignment,
        assignable_type: 'ExternalActivity',
        category: category,
        vol_program: true,
        track_group_id: nil
      )
      assignment.destroy
      expect(assignment.errors.messages).to be_empty
    end
  end

  describe '.destroy_assignment_set_activity' do
    let(:activity) { create(:activity) }
    let(:section_1) { create(:section) }
    let(:section_2) { create(:section) }

    let(:assignment_1) { create(:assignment, section: section_1, assignable: activity) }
    let(:assignment_2) { create(:assignment, section: section_2, assignable: activity) }

    let(:assignment_set_1) do
      create(
        :assignment_set,
        section: section_1,
        due_date: assignment_1.due_date
      )
    end

    let(:assignment_set_2) do
      create(
        :assignment_set,
        section: section_2,
        due_date: assignment_2.due_date
      )
    end

    before do
      create(
        :assignment_set_activity,
        activity: activity,
        assignment_set: assignment_set_1,
        assignment_set_rank: 1
      )
      create(
        :assignment_set_activity,
        activity: activity,
        assignment_set: assignment_set_2,
        assignment_set_rank: 1
      )
    end

    it 'destroys assignment set activity records of the corresponding assignment' do
      assignment_1.destroy_assignment_set_activity
      expect(
        AssignmentSetActivity.where(
          activity_id: activity.id,
          assignment_set_id: assignment_set_1.id
        ).count
      ).to eq(0)
    end
  end

  describe '.update_assignment' do
    before do
      school = build_stubbed(:school)
      program = build_stubbed(:program)
      instructor = build_stubbed(:instructor)
      course = create(:course, school: school, program: program, owner: instructor)
      @section = create(:section, course: course, instructor: instructor)
      @old_assignment = create(:assignment, section: @section, updated_at: 1.day.ago)
      @new_params = { due_date: 1.week.from_now.to_date }
    end

    it 'should delete the old assignment' do
      expect(@old_assignment).to receive(:destroy)
      allow(described_class).to receive(:create!)
      described_class.update_assignment(@old_assignment, @new_params)
    end

    it 'should trigger gradebook to delete the old assignment' do
      expect(@old_assignment).to receive(:notify_deletion)
      allow(described_class).to receive(:create_with_grades)
      described_class.update_assignment(@old_assignment, @new_params)
    end

    it 'deletes the old assignment and creates a new one with updated params' do
      new_assignment = described_class.update_assignment(@old_assignment, @new_params)
      expect(described_class.where(id: @old_assignment.id)).to be_empty
      expect(new_assignment.due_date).to eq(@new_params[:due_date])
      expect(new_assignment.updated_at).not_to eq(@old_assignment.updated_at)
    end

    it 'should reset the updated at attribute to its most recent update' do
      Timecop.freeze do
        new_assignment = described_class.update_assignment(@old_assignment, @new_params)
        expect(new_assignment.updated_at).to be_within(1).of(Time.zone.now)
      end
    end

    context 'when re-assigning a timed assessment' do
      before do
        allow(@old_assignment).to receive(:assessment?).and_return(true)
      end

      context 'when clearing the assignment time_limit' do
        before do
          allow(@old_assignment).to receive(:time_limit).and_return(60)
        end

        it 'deletes any student time_limit records' do
          new_params = { due_date: 1.week.from_now.to_date,
                         assigned_assessment_detail_attributes: { time_limit: '' } }
          expect(AssessmentStudentTimeLimit)
            .to receive(:delete_time_limits)
            .with(@old_assignment.section_id, @old_assignment.assignable_id)

          described_class.update_assignment(@old_assignment, new_params)
          expect(described_class.last.time_limit).to eq 0
        end
      end

      context 'when changing the assignment time limit' do
        it 'does not change the student time limits' do
          new_params = { due_date: 1.week.from_now.to_date,
                         assigned_assessment_detail_attributes: { time_limit: '45' } }
          expect(AssessmentStudentTimeLimit)
            .to_not receive(:delete_time_limits)

          described_class.update_assignment(@old_assignment, new_params)
          expect(described_class.last.time_limit).to eq 45
        end
      end
    end

    context 'when re-assigning an assignment that is part of an assignment set' do
      context 'when the assignment is reassigned to a new due date' do
        let(:activity) { create(:activity) }

        let(:other_assignment) do
          create(
            :assignment,
            section: @section,
            assignable: activity,
            due_date: @new_params[:due_date]
          )
        end

        let(:assignment_set_1) do
          create(
            :assignment_set,
            section: @section,
            due_date: @old_assignment.due_date
          )
        end

        let(:assignment_set_2) do
          create(
            :assignment_set,
            section: @section,
            due_date: @new_params[:due_date]
          )
        end

        before do
          create(
            :assignment_set_activity,
            activity: Activity.find(@old_assignment.assignable_id),
            assignment_set: assignment_set_1,
            assignment_set_rank: 1
          )

          create(
            :assignment_set_activity,
            activity: activity,
            assignment_set: assignment_set_2,
            assignment_set_rank: 1
          )
        end

        it 'destroys assignment set activity records of the old assignmen' do
          described_class.update_assignment(@old_assignment, @new_params)
          expect(
            AssignmentSetActivity.where(
              activity_id: @old_assignment.assignable_id,
              assignment_set_id: assignment_set_1.id
            ).count
          ).to eq(0)
        end

        it 'creates an assignment set activity for the new assignment' do
          new_assignment = described_class.update_assignment(@old_assignment, @new_params)
          expect(
            AssignmentSetActivity.where(
              activity_id: new_assignment.assignable_id,
              assignment_set_id: assignment_set_2.id
            ).count
          ).to eq(1)
        end

        it 'creates an assignment set activity for the new assignment with the expected rank' do
          other_assignment_rank = AssignmentSetActivity.find_by(
            activity_id: other_assignment.assignable_id,
            assignment_set: assignment_set_2
          ).assignment_set_rank
          new_assignment = described_class.update_assignment(@old_assignment, @new_params)
          expect(
            AssignmentSetActivity.find_by(
              activity_id: new_assignment.assignable_id,
              assignment_set_id: assignment_set_2.id
            ).assignment_set_rank
          ).to eq(other_assignment_rank + 1)
        end
      end
    end
  end

  describe '#grade_availability' do
    it 'should return the value of grade_availability table as a symbol' do
      assignment = create(:assignment, grade_availability: 'some_text')
      expect(assignment.grade_availability.class).to eq(Symbol)
    end
  end

  describe '.shown?' do
    it 'is false when show date/time is not set' do
      assignment = create(:assignment, assignable_type: 'Activity', assignable: activity, show_at: nil)
      expect(assignment).not_to be_shown
    end

    it 'is false when show date/time is in the future' do
      assignment = create(:assignment, assignable_type: 'Activity', assignable: activity, show_at: 1.minute.from_now)
      expect(assignment).not_to be_shown
    end

    it 'is true when show date/time is in the past' do
      assignment = create(:assignment, assignable_type: 'Activity', assignable: activity, show_at: 1.minute.ago)
      expect(assignment).to be_shown
    end
  end

  describe '#due_time' do
    before do
      @section_due_time = 2.day.ago.to_time
      allow(section).to receive(:due_time).and_return(@section_due_time)
    end

    context 'when custom_due_time is not set' do
      it "returns the assignment's section due time" do
        expect(assignment.due_time).to eq(@section_due_time)
      end
    end

    context 'when custom_due_time is set' do
      before do
        @time = 1.day.ago.to_time
        allow(assignment).to receive(:custom_due_time).and_return(@time)
      end

      it 'returns custom_due_time value' do
        expect(assignment.due_time).to eq(@time)
      end
    end
  end

  describe '#scoring_ruleset' do
    it 'returns the ruleset of the assignment category' do
      ruleset = build_stubbed(:scoring_ruleset)
      category = build_stubbed(:category)
      allow(category).to receive(:current_scoring_ruleset).and_return(ruleset)
      expect(described_class.new(category: category).scoring_ruleset).to eq(ruleset)
    end
  end

  describe '#disable_enhanced_feedback?' do
    it 'returns true if enhanced feedback is disabled for the assigned category' do
      category = create(:category, enhanced_feedback_disabled: true)
      expect(described_class.new(category: category).disable_enhanced_feedback?).to be_truthy
    end

    it 'returns false if enhanced feedback is enabled for the assigned category' do
      category = create(:category, enhanced_feedback_disabled: false)
      assignment = expect(described_class.new(category: category).disable_enhanced_feedback?).to be_falsey
    end
  end

  describe '#has_password?' do
    context 'when the assignment has an assigned_assessment_detail' do
      let(:detail) { AssignedAssessmentDetail.new }
      it "returns true if the detail's password is a non-empty string" do
        detail.password = 'password'
        assignment = create(:assignment, assigned_assessment_detail: detail)
        expect(assignment.has_password?).to be_truthy
      end

      it "returns false if the detail's password is an empty string" do
        assignment = create(:assignment, assigned_assessment_detail: detail)
        expect(assignment.has_password?).to be_falsey
      end
    end

    context 'when the assignment has no assigned_assessment_detail' do
      it 'returns false' do
        assignment = create(:assignment)
        expect(assignment.has_password?).to be_falsey
      end
    end
  end

  describe '#time_limit' do
    let(:detail) { AssignedAssessmentDetail.new }
    context 'when the time limit is set' do
      it 'returns the time limit' do
        detail.time_limit = 100
        assignment = create(:assignment, assigned_assessment_detail: detail)
        expect(assignment.time_limit).to eq(100)
      end
    end

    context 'when the time limit is not set' do
      it 'returns 0' do
        detail.time_limit = nil
        assignment = create(:assignment, assigned_assessment_detail: detail)
        expect(assignment.time_limit).to eq(0)
      end
    end

    context 'when there are no assigned assessment details' do
      it 'returns 0' do
        detail = nil
        assignment = create(:assignment, assigned_assessment_detail: detail)
        expect(assignment.time_limit).to eq(0)
      end
    end
  end

  describe 'update_gradebook in after_commit' do
    let(:category) { create(:category) }
    let(:activity) { create(:activity) }
    let(:section) { create(:section_with_course) }
    let(:assignment) { create(:assignment, section: section) }

    context 'given an Activity Assignment' do
      it 'triggers update_gradebook in after_commit' do
        assignment.due_date = DateTime.now + 3.month
        expect(assignment).to receive(:update_gradebook)
        assignment.save
      end

      it 'triggers notify_update on creation' do
        new_assignment = described_class.new(due_date: DateTime.now + 3.month,
                                             category: category,
                                             assignable: activity,
                                             assignable_type: 'Activity',
                                             section_id: section.id)
        expect(new_assignment).to receive(:notify_update).at_least(:once)
        new_assignment.save
      end

      it 'triggers notify_deletion on destroy' do
        new_assignment = described_class.new(due_date: DateTime.now + 3.month,
                                             category: category,
                                             assignable: activity,
                                             assignable_type: 'Activity',
                                             section_id: section.id)
        new_assignment.save
        expect(new_assignment).to receive(:notify_deletion)
        new_assignment.destroy
      end
    end
  end

  describe '#has_multiple_due_dates?' do
    context 'when assignment is not individually assignable' do
      it 'returns false' do
        assignment = create(:assignment, individually_assignable: false)
        expect(assignment.has_multiple_due_dates?).to be false
      end
    end

    context 'when assignment is individually assignable but not assigned' do
      it 'returns false' do
        assignment = create(:assignment, individually_assignable: true)
        expect(assignment.has_multiple_due_dates?).to be false
      end
    end

    context 'when assignment is individually assigned' do
      context 'when all individual assignments have a null due date' do
        it 'returns false' do
          assignment = create(:assignment, individually_assignable: true)

          create(
            :individual_assignment,
            activity_id: assignment.assignable_id,
            due_date: nil,
            section_id: assignment.section_id
          )

          expect(assignment.has_multiple_due_dates?).to be false
        end
      end

      context 'when all individual assignments have non-null due date == assignment due date' do
        it 'returns false' do
          assignment = create(:assignment, individually_assignable: true)

          create(
            :individual_assignment,
            activity_id: assignment.assignable_id,
            due_date: assignment.due_date,
            section_id: assignment.section_id
          )
          create(
            :individual_assignment,
            section_id: assignment.section_id,
            due_date: assignment.due_date,
            activity_id: assignment.assignable_id
          )
          expect(assignment.has_multiple_due_dates?).to be false
        end
      end

      context 'when 1+ individual assignment has non-null due_date != assignment due_date' do
        it 'returns true' do
          assignment = create(:assignment, individually_assignable: true)

          create(
            :individual_assignment,
            activity_id: assignment.assignable_id,
            due_date: nil,
            section_id: assignment.section_id
          )
          create(
            :individual_assignment,
            section_id: assignment.section_id,
            due_date: assignment.due_date + 1.day,
            activity_id: assignment.assignable_id
          )
          expect(assignment.has_multiple_due_dates?).to be true
        end
      end
    end
  end
end

describe Assignment::NextRankFinder, test_debt: true do
  describe '.next_rank' do
    let(:today) { Date.today.strftime('%I/%d/%Y') }
    let(:tomorrow) { Date.tomorrow.to_date.to_s }
    let(:section) { create(:section) }

    context 'with assignments in different lessons' do
      before do
        @unit_1 = create(:unit)

        l1_strand = build_stubbed(:toc_entry)
        @lesson_1 = @unit_1.lessons.first
        @lesson_1.toc_entries = [l1_strand]
        @lesson_1.save!

        l2_strand = build_stubbed(:toc_entry)
        @lesson_2 = create(:lesson, unit: @unit_1, rank: 2)
        @lesson_2.toc_entries = [l2_strand]
        @lesson_2.save!

        @l1_activity = create(:activity, lesson: @lesson_1, toc_location: l1_strand,
                                         toc_location_rank: 50, concept_rank: 50)
        @l2_activity = create(:activity, lesson: @lesson_2, toc_location: l2_strand,
                                         toc_location_rank: 30, concept_rank: 30)

        @unit_2 = create(:unit, rank: (@unit_1.rank + 1))
        @unit_2_lesson = @unit_2.lessons.first
        u2_strand = build_stubbed(:toc_entry)
        @unit_2_lesson.toc_entries = [u2_strand]
        @unit_2_lesson.save!
        @u2_activity = create(:activity, lesson: @unit_2_lesson, toc_location: u2_strand,
                                         toc_location_rank: 10, concept_rank: 10)
      end

      context 'when activities later in the toc in a different lesson are assigned for the same date' do
        it 'returns the rank of the assigned activity appearing next in the toc' do
          create(:assignment, section: section, due_date: today, rank: 3, assignable: @l2_activity)
          expect(described_class.new(section, today, @l1_activity).next_rank).to eq(3)
        end
      end

      context 'when activities earlier in the ToC in a different lesson are assigned for the same due date' do
        it 'returns the rank + 1 of the assigned activity appearing previously in the toc' do
          create(:assignment, section: section, due_date: today, rank: 7, assignable: @l1_activity)
          expect(described_class.new(section, today, @l2_activity).next_rank).to eq(8)
        end
      end

      context 'when activities later in the toc in a different units are assigned for the same date' do
        it 'returns the rank of the assigned activity appearing next in the toc' do
          create(:assignment, section: section, due_date: today, rank: 11, assignable: @u2_activity)
          expect(described_class.new(section, today, @l2_activity).next_rank).to eq(11)
        end
      end

      context 'when activities earlier in the ToC in a different units are assigned for the same due date' do
        it 'returns the rank + 1 of the assigned activity appearing previously in the toc' do
          create(:assignment, section: section, due_date: today, rank: 13, assignable: @l2_activity)
          expect(described_class.new(section, today, @u2_activity).next_rank).to eq(14)
        end
      end
    end

    context 'with assignments in a lesson with strands and substrands' do
      let(:lesson) do
        create(:lesson, toc_entries_xml: Nokogiri::XML(File.open('spec/fixtures/xml/lesson.xml')).to_xml,
                        unit: create(:unit))
      end

      # These values come from the lesson xml fixture
      let(:substrand_1_id) { 214600000 }
      let(:substrand_2_id) { 214800000 }
      let(:strand_1_id) { 2146 }
      let(:strand_2_id) { 2147 }

      let!(:substrand_1_activity_1) do
        create(:activity, lesson: lesson, title: 'AA', toc_location: substrand_1_id,
                          concept_rank: 10, toc_location_rank: 10)
      end
      let!(:substrand_1_activity_2) do
        create(:activity, lesson: lesson, title: 'BB', toc_location: substrand_1_id,
                          concept_rank: 20, toc_location_rank: 20)
      end
      let!(:substrand_1_activity_3) do
        create(:activity, lesson: lesson, title: 'CC', toc_location: substrand_1_id,
                          concept_rank: 30, toc_location_rank: 30)
      end
      let!(:substrand_2_activity_1) do
        create(:activity, lesson: lesson, title: 'DD', toc_location: substrand_2_id,
                          concept_rank: 10, toc_location_rank: 10)
      end
      let!(:substrand_2_activity_2) do
        create(:activity, lesson: lesson, title: 'EE', toc_location: substrand_2_id,
                          concept_rank: 20, toc_location_rank: 20)
      end
      let!(:substrand_2_activity_3) do
        create(:activity, lesson: lesson, title: 'FF', toc_location: substrand_2_id,
                          concept_rank: 30, toc_location_rank: 30)
      end

      context 'when nothing is assigned' do
        it 'returns 1 regardless of toc position' do
          expect(described_class.new(section, today, substrand_1_activity_1).next_rank).to eq(1)
          expect(described_class.new(section, today, substrand_1_activity_3).next_rank).to eq(1)
          expect(described_class.new(section, today, substrand_2_activity_2).next_rank).to eq(1)
        end
      end

      context 'when activities later in the toc in the same substrand are assigned for the same date' do
        it 'returns the rank of the assigned activity appearing next in the toc' do
          create(:assignment, section: section, due_date: today, rank: 5, assignable: substrand_1_activity_2)
          create(:assignment, section: section, due_date: today, rank: 7, assignable: substrand_1_activity_3)
          expect(described_class.new(section, today, substrand_1_activity_1).next_rank).to eq(5)
        end
      end

      context 'when activities later in the toc in the same substrand are assigned for different dates' do
        it 'returns the rank of the activity appearing next in the toc that is assigned for the same date' do
          create(:assignment, section: section, due_date: tomorrow, rank: 5, assignable: substrand_1_activity_2)
          create(:assignment, section: section, due_date: today, rank: 7, assignable: substrand_1_activity_3)
          expect(described_class.new(section, today, substrand_1_activity_1).next_rank).to eq(7)
          expect(described_class.new(section, tomorrow, substrand_1_activity_1).next_rank).to eq(5)
        end
      end

      context 'when activities later in the toc in different substrands are assigned for the same date' do
        it 'returns the rank of the assigned activity appearing next in the toc' do
          create(:assignment, section: section, due_date: today, rank: 7, assignable: substrand_2_activity_2)
          create(:assignment, section: section, due_date: today, rank: 9, assignable: substrand_2_activity_3)
          expect(described_class.new(section, today, substrand_1_activity_3).next_rank).to eq(7)
        end
      end

      context 'when activities earlier and later in the toc in the same substrand are assigned for the same date' do
        it 'returns the rank of the assigned activity appearing next in the toc' do
          create(:assignment, section: section, due_date: today, rank: 9, assignable: substrand_1_activity_1)
          create(:assignment, section: section, due_date: today, rank: 11, assignable: substrand_1_activity_3)
          expect(described_class.new(section, today, substrand_1_activity_2).next_rank).to eq(11)
        end
      end

      context 'when activities later in the toc in different strands are assigned for the same date' do
        let!(:strand_2_activity_1) do
          create(:activity, lesson: lesson, title: 'GG', toc_location: strand_2_id,
                            concept_rank: 10, toc_location_rank: 10)
        end

        it 'returns the rank of the assigned activity appearing next in the toc' do
          create(:assignment, section: section, due_date: today, rank: 11, assignable: substrand_1_activity_1)
          create(:assignment, section: section, due_date: today, rank: 13, assignable: strand_2_activity_1)
          expect(described_class.new(section, today, substrand_1_activity_2).next_rank).to eq(13)
        end
      end

      context 'when activities earlier in the toc in the same substrand are assigned for the same date' do
        it 'returns the 1 + rank of the assigned activity appearing previously in the toc' do
          create(:assignment, section: section, due_date: today, rank: 5, assignable: substrand_1_activity_1)
          create(:assignment, section: section, due_date: today, rank: 7, assignable: substrand_1_activity_2)
          expect(described_class.new(section, today, substrand_1_activity_3).next_rank).to eq(8)
        end
      end

      context 'when activities earlier in the toc in the same substrand are assigned for different dates' do
        it 'returns the rank of the activity appearing previously in the toc that is assigned for the same date' do
          create(:assignment, section: section, due_date: tomorrow, rank: 8, assignable: substrand_1_activity_1)
          create(:assignment, section: section, due_date: today, rank: 10, assignable: substrand_1_activity_2)
          expect(described_class.new(section, tomorrow, substrand_1_activity_3).next_rank).to eq(9)
          expect(described_class.new(section, today, substrand_1_activity_3).next_rank).to eq(11)
        end
      end

      context 'when activities earlier in the toc in different substrands are assigned for the same date' do
        it 'returns the rank of the assigned activity appearing previously in the toc' do
          create(:assignment, section: section, due_date: today, rank: 4, assignable: substrand_1_activity_2)
          create(:assignment, section: section, due_date: today, rank: 6, assignable: substrand_1_activity_3)
          expect(described_class.new(section, today, substrand_2_activity_2).next_rank).to eq(7)
        end
      end

      context 'when activities earlier in the toc in different strands are assigned for the same date' do
        let!(:strand_2_activity_1) do
          create(:activity, lesson: lesson, title: 'GG', toc_location: strand_2_id,
                            concept_rank: 10, toc_location_rank: 10)
        end

        it 'returns the rank of the assigned activity appearing next in the toc' do
          create(:assignment, section: section, due_date: today, rank: 2, assignable: substrand_1_activity_2)
          create(:assignment, section: section, due_date: today, rank: 4, assignable: substrand_2_activity_2)
          expect(described_class.new(section, today, strand_2_activity_1).next_rank).to eq(5)
        end
      end

      context 'when activities earlier and later in the toc are assigned and multiple assignments in between are made' do
        it 'returns the same ranks regardless of the order the new assignments are done' do
          create(:assignment, section: section, due_date: today, rank: 10, assignable: substrand_1_activity_1)
          create(:assignment, section: section, due_date: today, rank: 20, assignable: substrand_2_activity_3)

          next_rank_1 = described_class.new(section, today, substrand_1_activity_3).next_rank
          assignment_1 = create(:assignment, section: section, due_date: today, rank: next_rank_1,
                                             assignable: substrand_1_activity_3)

          next_rank_2 = described_class.new(section, today, substrand_2_activity_1).next_rank
          assignment_2 = create(:assignment, section: section, due_date: today, rank: next_rank_2,
                                             assignable: substrand_2_activity_1)

          expect(assignment_1.reload.rank).to eq(20)
          expect(assignment_2.reload.rank).to eq(20)

          assignment_1.destroy
          assignment_2.destroy

          # Do the assignments in the opposite toc order as above
          next_rank_1 = described_class.new(section, today, substrand_2_activity_1).next_rank
          assignment_1 = create(:assignment, section: section, due_date: today, rank: next_rank_1,
                                             assignable: substrand_2_activity_1)

          next_rank_2 = described_class.new(section, today, substrand_1_activity_3).next_rank
          assignment_2 = create(:assignment, section: section, due_date: today, rank: next_rank_2,
                                             assignable: substrand_1_activity_3)

          expect(assignment_1.rank).to eq(20)
          expect(assignment_2.rank).to eq(20)
        end
      end
    end
  end
end
