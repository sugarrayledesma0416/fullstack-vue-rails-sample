require 'timecop'

describe InstructorAssignablesPresenter do
  include ActionView::Helpers::TagHelper
  include ApplicationHelper

  before do
    @focus = double(Focus).as_null_object
    @opts = {
      activity_ids: [123, 456],
      resource_ids: [567, 890],
      program_id: program.id
    }
    allow(@focus).to receive(:program).and_return(program)
  end

  let(:program) { create(:program) }
  let(:sections)   { [build_stubbed(:section)] }
  let(:lesson) { build_stubbed(:lesson_with_toc_entries) }
  let(:lesson_2) { build_stubbed(:lesson_with_toc_entries) }
  let(:toc_entry) { build_stubbed(:toc_entry) }
  let(:toc_entry_2) { build_stubbed(:toc_entry) }
  let(:activity)   { build_stubbed(:activity) }
  let(:activity_2) { build_stubbed(:activity) }
  let(:resource)   { build_stubbed(:resource) }
  let(:activity_assignment)   { build_stubbed(:assignment, :section => sections.first, :assignable => activity) }
  let(:activity_assignment_2)   { build_stubbed(:assignment, :section => sections.first, :assignable => activity) }
  let(:activity_2_assignment) { build_stubbed(:assignment, :section => sections.first, :assignable => activity_2) }
  let(:activity_message_chain) { %i[where joins joins includes select order] }

  def prep_build_assignables(return_value = [])
    allow(Activity).to receive_message_chain(*activity_message_chain).and_return(return_value)
    allow_any_instance_of(Activity).to receive(:effective_rank).and_return(0)
  end

  context 'when building the presenter' do
    let(:activity_1) { create(:activity, toc_location_rank: 1) }
    let(:activity_2) { create(:activity, toc_location_rank: 2) }
    let(:activity_3) { create(:activity, toc_location_rank: 20) }
    let(:activity_4) { create(:activity, toc_location_rank: 1) }
    let(:section)    { create(:section) }
    let(:opts) { { :activity_ids => [],
                   :resource_ids => [],
                   :program_id => program.id } }

    before do
      allow(@focus).to receive(:sections).and_return([section])
      allow(@focus).to receive(:section).and_return(section)
    end

    context 'when there are no assignments' do
      it 'returns assignable instances for the selected activities' do
        opts[:activity_ids] = [activity_1.id, activity_2.id, activity_3.id, activity_4.id]
        presenter = InstructorAssignablesPresenter.new(@focus, opts)
        expect(presenter.assignables.map(&:assignable)).to match_array([activity_1, activity_2, activity_3, activity_4])
      end
    end

    context 'when there are activity assignments in different sections' do
      it 'returns assignable instances for the selected activities only' do
        create(:assignment, rank: 1, :assignable => activity_1, :section => create(:section))
        opts[:activity_ids] = [activity_1.id]
        presenter = InstructorAssignablesPresenter.new(@focus, opts)
        expect(presenter.assignables.map(&:assignable)).to eq([activity_1])
      end
    end

    context 'when assignments are ordered by ranks' do
      let(:unit_one) { create(:unit, rank: 1) }
      let(:lesson_one) { create(:lesson, unit: unit_one, rank: 1) }
      let(:concept_one) { create(:concept, lesson: lesson_one, rank: 1) }
      let(:activity_one) { create(:activity) }
      let(:activity_two) { create(:activity) }

      it 'loads the activities ordered by assignment_set_rank when there is a custom order' do
        assignment_one = create(:assignment, assignable: activity_one, section_id: section.id)
        assignment_two = create(:assignment, assignable: activity_two, section_id: section.id)
        assignment_set_one = create(:assignment_set, section: section, due_date: assignment_one.due_date)
        assignment_set_two = create(:assignment_set, section: section, due_date: assignment_two.due_date)
        create(:assignment_set_activity, activity: activity_one, assignment_set: assignment_set_one, assignment_set_rank: 3)
        create(:assignment_set_activity, activity: activity_two, assignment_set: assignment_set_two, assignment_set_rank: 2)
        @opts[:activity_ids] = [activity_one, activity_two]

        @presenter = InstructorAssignablesPresenter.new(@focus, @opts)
        expect(@presenter.assignables.map(&:id)).to eq([activity_two.id, activity_one.id])
      end

      it 'loads the activities ordered by assignment rank when there is no assignment_set_rank' do
        create(:assignment, assignable: activity_one, section_id: section.id, rank: 4)
        create(:assignment, assignable: activity_two, section_id: section.id, rank: 3)
        @opts[:activity_ids] = [activity_one, activity_two]

        @presenter = InstructorAssignablesPresenter.new(@focus, @opts)
        expect(@presenter.assignables.map(&:id)).to eq([activity_two.id, activity_one.id])
      end

      it 'loads the activities ordered by unit rank when assignment rank tie' do
        unit_two = create(:unit, rank: 2)
        lesson_two = create(:lesson, unit: unit_two)
        activity_one = create(:activity, lesson: lesson_two)
        activity_two = create(:activity, lesson: lesson_one)
        create(:assignment, assignable: activity_one, section_id: section.id, rank: 1)
        create(:assignment, assignable: activity_two, section_id: section.id, rank: 1)
        @opts[:activity_ids] = [activity_one, activity_two]

        @presenter = InstructorAssignablesPresenter.new(@focus, @opts)
        expect(@presenter.assignables.map(&:id)).to eq([activity_two.id, activity_one.id])
      end

      it 'loads the activities ordered by lesson rank when assignment rank and unit rank tie' do
        lesson_two = create(:lesson, unit: unit_one, rank: 4)
        activity_one = create(:activity, lesson: lesson_two)
        activity_two = create(:activity, lesson: lesson_one)
        create(:assignment, assignable: activity_one, section_id: section.id, rank: 1)
        create(:assignment, assignable: activity_two, section_id: section.id, rank: 1)
        @opts[:activity_ids] = [activity_one, activity_two]

        @presenter = InstructorAssignablesPresenter.new(@focus, @opts)
        expect(@presenter.assignables.map(&:id)).to eq([activity_two.id, activity_one.id])
      end

      it 'loads the activities ordered by concept rank when assignment rank, unit rank ' \
         'and lesson rank tie' do
        concept_two = create(:concept, lesson: lesson_one, rank: 3)
        activity_one = create(:activity, lesson: lesson_one, concept: concept_two)
        activity_two = create(:activity, lesson: lesson_one, concept: concept_one)
        create(:assignment, assignable: activity_one, section_id: section.id, rank: 1)
        create(:assignment, assignable: activity_two, section_id: section.id, rank: 1)
        @opts[:activity_ids] = [activity_one, activity_two]

        @presenter = InstructorAssignablesPresenter.new(@focus, @opts)
        expect(@presenter.assignables.map(&:id)).to eq([activity_two.id, activity_one.id])
      end

      it 'loads the activities ordered by activity concept_rank when assignment rank, unit rank, ' \
         'lesson rank and concept rank tie' do
        activity_one = create(:activity, lesson: lesson_one, concept: concept_one, concept_rank: 3)
        activity_two = create(:activity, lesson: lesson_one, concept: concept_one, concept_rank: 2)
        create(:assignment, assignable: activity_one, section_id: section.id, rank: 1)
        create(:assignment, assignable: activity_two, section_id: section.id, rank: 1)
        @opts[:activity_ids] = [activity_one, activity_two]

        @presenter = InstructorAssignablesPresenter.new(@focus, @opts)
        expect(@presenter.assignables.map(&:id)).to eq([activity_two.id, activity_one.id])
      end

      it 'loads the activities ordered by activity toc_location_rank when assignment rank, ' \
         'unit rank, lesson rank, concept rank and activity concept_rank tie' do
        activity_one = create(:activity, lesson: lesson_one, concept: concept_one, concept_rank: 1, toc_location_rank: 3)
        activity_two = create(:activity, lesson: lesson_one, concept: concept_one, concept_rank: 1, toc_location_rank: 2)
        create(:assignment, assignable: activity_one, section_id: section.id, rank: 1)
        create(:assignment, assignable: activity_two, section_id: section.id, rank: 1)
        @opts[:activity_ids] = [activity_one, activity_two]

        @presenter = InstructorAssignablesPresenter.new(@focus, @opts)
        expect(@presenter.assignables.map(&:id)).to eq([activity_two.id, activity_one.id])
      end
    end

    it 'filters out assignments by section' do
      section_1 = create(:section)
      section_2 = create(:section)
      create(:assignment, rank: 3, assignable: activity_1, section: section_1)
      create(:assignment, rank: 3, assignable: activity_1, section: section_2)
      assignments_by_assignable = {
        activity_1 => [double(Assignment), double(Assignment)]
      }

      allow(Assignment).to receive_message_chain(:by_activities_and_sections, :group_by)
        .and_return(assignments_by_assignable)
      @opts[:activity_ids] = [activity_1]

      @presenter = InstructorAssignablesPresenter.new(@focus, @opts)

      expect(@presenter.assignables.map(&:assignable)).to eq([activity_1])
    end

    context 'with assignments for multiple different assignables' do
      # these should really be integration tests,
      # but since they are only used in javascript-heavy page elements,
      # they exist here as specs due to watir's shortcomings
      before do
        @sections = [build_stubbed(:section)]
        @activity = build_stubbed(:activity)
        @activity_assignable = double(InstructorAssignablesPresenter::Assignable, :assignable => @activity)
        @activity_assignment = create(:assignment, :assignable => @activity_assignable.assignable)
        allow(@focus).to receive(:sections).and_return(@sections)
        prep_build_assignables([@activity])
      end

      it 'creates assignables with the appropriate assignments' do
        allow(Assignment).to receive_message_chain(:by_activities_and_sections, :group_by).and_return({ @activity => [@activity_assignment] })

        expect(InstructorAssignablesPresenter::Assignable).to receive(:new).with(
          @activity,
          [@activity_assignment],
          focused_on_only_one_section: @focus.focused_on_only_one_section?,
          sections: @sections
        ).and_return(@activity_assignable)

        @presenter = InstructorAssignablesPresenter.new(@focus, @opts)
      end

      it 'stores the appropriate assignables' do
        allow(Assignment).to receive_message_chain(:by_activities_and_sections, :group_by).and_return({ @activity => [@activity_assignment] })

        allow(InstructorAssignablesPresenter::Assignable).to receive(:new).with(
          @activity,
          [@activity_assignment],
          focused_on_only_one_section: @focus.focused_on_only_one_section?,
          sections: @sections
        ).and_return(@activity_assignable)

        @presenter = InstructorAssignablesPresenter.new(@focus, @opts)
        expect(@presenter.assignables).to include @activity_assignable
        expect(@presenter.assignables.count).to eql 1
      end
    end
  end

  describe 'individual assignment methods' do
    def assign(activity, section, individually_assignable)
      create(
        :assignment,
        assignable: activity,
        individually_assignable: individually_assignable,
        section: section
      )
    end

    let(:activity_1) { create(:activity, toc_location_rank: 1) }
    let(:activity_2) { create(:activity, toc_location_rank: 2) }
    let(:section_1) { create(:section) }
    let(:presenter) { described_class.new(mock_focus, opts) }

    let(:single_section_focus) do
      instance_double(
        Focus,
        focused_on_only_one_section?: true,
        section: section_1,
        sections: [section_1]
      )
    end

    describe '#has_mixed_individually_assignable_status?' do
      context 'when focused on just one section,' do
        let(:mock_focus) { single_section_focus }

        context 'when only one activity is specified,' do
          let(:opts) { { activity_ids: [activity_1.id], program_id: program.id } }

          it 'is false if the activity is not assigned' do
            expect(presenter).not_to have_mixed_individually_assignable_status
          end

          it 'is false if the activity is assigned and individually-assignable' do
            assign(activity_1, section_1, true)

            expect(presenter).not_to have_mixed_individually_assignable_status
          end

          it 'is false if the activity is assigned and not individually-assignable' do
            assign(activity_1, section_1, false)
            expect(presenter).not_to have_mixed_individually_assignable_status
          end
        end

        context 'when multiple activities are specified,' do
          let(:opts) do
            { activity_ids: [activity_1.id, activity_2.id], program_id: program.id }
          end

          it 'is false if all activities are unassigned' do
            expect(presenter).not_to have_mixed_individually_assignable_status
          end

          it 'is false if all activities are assigned and individually-assignable' do
            assign(activity_1, section_1, true)
            assign(activity_2, section_1, true)

            expect(presenter).not_to have_mixed_individually_assignable_status
          end

          it 'is false if all activities are assigned and not individually-assignable' do
            assign(activity_1, section_1, false)
            assign(activity_2, section_1, false)

            expect(presenter).not_to have_mixed_individually_assignable_status
          end

          it 'is false if some activities are assigned and not individually-assignable ' \
             'and other activities are not assigned' do
            assign(activity_1, section_1, false)

            expect(presenter).not_to have_mixed_individually_assignable_status
          end

          it 'is true if some activities are assigned and individually-assignable ' \
             'and other activities are not assigned' do
            assign(activity_1, section_1, true)

            expect(presenter).to have_mixed_individually_assignable_status
          end

          it 'is true if some activities are assigned and individually-assignable ' \
             'and other activities are assigned and not individually-assignable' do
            assign(activity_1, section_1, true)
            assign(activity_2, section_1, false)

            expect(presenter).to have_mixed_individually_assignable_status
          end
        end
      end

      context 'when focused on multiple sections,' do
        let(:section_2) { create(:section) }

        let(:mock_focus) do
          instance_double(
            Focus,
            focused_on_only_one_section?: false,
            section: section_1,
            sections: [section_1, section_2]
          )
        end

        context 'when only one activity is specified,' do
          let(:opts) { { activity_ids: [activity_1.id], program_id: program.id } }

          it 'is false if the activity is not assigned in any section' do
            expect(presenter).not_to have_mixed_individually_assignable_status
          end

          it 'is false if the activity is assigned and individually-assignable ' \
             'in all sections' do
            assign(activity_1, section_1, true)
            assign(activity_1, section_2, true)

            expect(presenter).not_to have_mixed_individually_assignable_status
          end

          it 'is false if the activity is assigned and not individually-assignable ' \
             'in all sections' do
            assign(activity_1, section_1, false)
            assign(activity_1, section_2, false)

            expect(presenter).not_to have_mixed_individually_assignable_status
          end

          it 'is false if the activity is assigned and not individually-assignable ' \
             'in some sections and not assigned in other sections' do
            assign(activity_1, section_1, false)

            expect(presenter).not_to have_mixed_individually_assignable_status
          end

          it 'is true if the activity is assigned and individually-assignable ' \
             'in some sections and not assigned in other sections' do
            assign(activity_1, section_1, true)

            expect(presenter).to have_mixed_individually_assignable_status
          end

          it 'is true if the activity is assigned and individually-assignable ' \
             'in some sections and assigned but not individually-assignable ' \
             'in other sections' do
            assign(activity_1, section_1, true)
            assign(activity_1, section_2, false)

            expect(presenter).to have_mixed_individually_assignable_status
          end
        end

        context 'when multiple activities are specified,' do
          let(:opts) do
            { activity_ids: [activity_1.id, activity_2.id], program_id: program.id }
          end

          it 'is false if all activities are unassigned in all sections' do
            expect(presenter).not_to have_mixed_individually_assignable_status
          end

          it 'is false if all activities are assigned and individually-assignable ' \
             'in all sections' do
            assign(activity_1, section_1, true)
            assign(activity_2, section_1, true)
            assign(activity_1, section_2, true)
            assign(activity_2, section_2, true)

            expect(presenter).not_to have_mixed_individually_assignable_status
          end

          it 'is false if all activities are assigned and not individually-assignable ' \
             'in all sections' do
            assign(activity_1, section_1, false)
            assign(activity_2, section_1, false)
            assign(activity_1, section_2, false)
            assign(activity_2, section_2, false)

            expect(presenter).not_to have_mixed_individually_assignable_status
          end

          it 'is false if some activities are assigned and not ' \
             'individually-assignable in some sections and some activities ' \
             'are not assigned in some sections' do
            assign(activity_1, section_1, false)
            assign(activity_2, section_2, false)

            expect(presenter).not_to have_mixed_individually_assignable_status
          end

          it 'is true if some activities are assigned and individually-assignable ' \
             'in some sections and not assigned in other sections' do
            assign(activity_1, section_1, true)
            assign(activity_2, section_1, false)

            expect(presenter).to have_mixed_individually_assignable_status
          end

          it 'is true if some activities are assigned and individually-assignable ' \
             'in some sections and assigned but not individually-assignable ' \
             'in other sections' do
            assign(activity_1, section_1, true)
            assign(activity_2, section_1, true)
            assign(activity_1, section_2, true)
            assign(activity_2, section_2, false)

            expect(presenter).to have_mixed_individually_assignable_status
          end
        end
      end
    end

    describe '#individually_assignable_options' do
      let(:mock_focus) { single_section_focus }

      let(:opts) do
        { activity_ids: [activity_1.id, activity_2.id], program_id: program.id }
      end

      it 'returns an array with just a "varies" option when assignments ' \
         'have varying individually_assignable statuses' do
        assign(activity_1, section_1, true)
        assign(activity_2, section_1, false)

        expect(presenter.individually_assignable_options).to eq(
          [['varies', '']]
        )
      end

      it 'returns an array with just a "Entire Section" and "Individual Students" ' \
         'option when assignments have the same individually_assignable status' do
        assign(activity_1, section_1, true)
        assign(activity_2, section_1, true)

        expect(presenter.individually_assignable_options).to eq(
          [['Entire Section', false], ['Individual Students', true]]
        )
      end
    end

    describe '#current_individually_assignable_value' do
      let(:mock_focus) { single_section_focus }

      let(:opts) do
        { activity_ids: [activity_1.id, activity_2.id], program_id: program.id }
      end

      it 'returns an empty string when assignments have varying ' \
         'individually_assignable statuses' do
        assign(activity_1, section_1, true)
        assign(activity_2, section_1, false)

        expect(presenter.current_individually_assignable_value).to eq('')
      end

      it 'returns true when all assignments are individually assignable' do
        assign(activity_1, section_1, true)
        assign(activity_2, section_1, true)

        expect(presenter.current_individually_assignable_value).to be true
      end

      it 'returns true when all assignments are not individually assignable' do
        assign(activity_1, section_1, false)
        assign(activity_2, section_1, false)

        expect(presenter.current_individually_assignable_value).to be false
      end
    end
  end

  describe "methods based on common values" do

    let(:assignable_1) { double('Assignable') }
    let(:assignable_2) { double('Assignable') }
    let(:presenter) { InstructorAssignablesPresenter.new(@focus, @opts) }

    before do
      prep_build_assignables
      allow(Assignment).to receive_message_chain(:by_activities_and_sections, :group_by).and_return({})
      allow(presenter).to receive(:assignables).and_return([assignable_1, assignable_2])
    end

    describe "#assignment_due_date" do
      let(:section) { build_stubbed(:section, :time_zone => "Pacific Time (US & Canada)") }

      before do
        allow(@focus).to receive(:sections).and_return([section])
      end

      around do |example|
        Timecop.freeze(Time.new(2017, 12, 27, 12, 0, 0)) do
          example.run
        end
      end

      context "when preferred assignment date exists" do
        before do
          @date = 2.day.from_now
          allow(presenter).to receive(:preferred_assignment_date).and_return(@date)
        end

        it "returns preferred assignment date if due_date is blank" do
          allow(assignable_1).to receive(:due_date).and_return('')
          allow(assignable_2).to receive(:due_date).and_return('')
          expect(presenter.assignment_due_date).to eql format_date_time(@date, :short)
        end

        it "returns blank if due_dates vary" do
          allow(assignable_1).to receive(:due_date).and_return(1.day.from_now)
          allow(assignable_2).to receive(:due_date).and_return(3.day.from_now)
          expect(presenter.assignment_due_date).to be_blank
        end

        it "returns the common due date if due_dates are same" do
          same_date = 1.day.from_now
          allow(assignable_1).to receive(:due_date).and_return(same_date)
          allow(assignable_2).to receive(:due_date).and_return(same_date)
          expect(presenter.assignment_due_date).to eql format_date_time(same_date, :short)
        end
      end

      context "when preferred assignment date does not  exists" do
        before do
          allow(presenter).to receive(:preferred_assignment_date).and_return(nil)
        end

        it "returns preferred assignment date if due_date is blank" do
          allow(assignable_1).to receive(:due_date).and_return('')
          allow(assignable_2).to receive(:due_date).and_return('')
          expect(presenter.assignment_due_date).to eql format_date_time(0.day.from_now, :short)
        end

        it "returns the common due date if due_dates are same" do
          same_date = 1.day.from_now
          allow(assignable_1).to receive(:due_date).and_return(same_date)
          allow(assignable_2).to receive(:due_date).and_return(same_date)
          expect(presenter.assignment_due_date).to eql format_date_time(same_date, :short)
        end
      end
    end

    describe "#current_track_group_name" do

      context 'when track_group is the same for all assignments of all assignables' do
        it 'returns the common track_group id' do
          allow(assignable_1).to receive(:track_group_name).and_return(2)
          allow(assignable_2).to receive(:track_group_name).and_return(2)
          expect(presenter.current_track_group_name).to eql 2
        end
      end

      context 'when track_group is different for assignments of all assignables' do
        it 'returns nil' do
          allow(assignable_1).to receive(:track_group_name).and_return(1)
          allow(assignable_2).to receive(:track_group_name).and_return(2)
          expect(presenter.current_track_group_name).to be_nil
        end
      end
    end

    describe "#current_category_id" do

      context 'when category is the same for all assignments of all assignables' do
        it 'returns the common category id' do
          allow(assignable_1).to receive(:category_id).and_return(2)
          allow(assignable_2).to receive(:category_id).and_return(2)
          expect(presenter.current_category_id).to eql 2
        end
      end

      context 'when category is different for assignments of all assignables' do
        it 'returns nil' do
          allow(assignable_1).to receive(:category_id).and_return(1)
          allow(assignable_2).to receive(:category_id).and_return(2)
          expect(presenter.current_category_id).to be_nil
        end
      end
    end

    describe "#assessment_release_status" do
      let(:section) { build_stubbed(:section, :time_zone => "Pacific Time (US & Canada)") }

      before do
        allow(@focus).to receive(:sections).and_return([section])
      end

      context 'when assessment availability is the same for all assignments of all assignables' do
        it 'returns the common assessment availability' do
          allow(assignable_1).to receive(:show_assessment).and_return('some_value')
          allow(assignable_2).to receive(:show_assessment).and_return('some_value')
          expect(presenter.assessment_release_status).to eql 'some_value'
        end
      end

      context 'when assessment availability is different for assignments of all assignables' do
        it 'returns nil' do
          allow(assignable_1).to receive(:show_assessment).and_return('some_value')
          allow(assignable_2).to receive(:show_assessment).and_return('another_value')
          expect(presenter.assessment_release_status).to be_nil
        end
      end
    end

    describe "#assessment_grade_status" do
      let(:section) { build_stubbed(:section, :time_zone => "Pacific Time (US & Canada)") }

      before do
        allow(@focus).to receive(:sections).and_return([section])
      end

      context 'when assessment grade availability is the same for all assignments of all assignables' do
        it 'returns the common assessment grade availability' do
          allow(assignable_1).to receive(:grade_availability).and_return(:some_value)
          allow(assignable_2).to receive(:grade_availability).and_return(:some_value)
          expect(presenter.assessment_grade_status).to eql :some_value
        end
      end

      context 'when assessment grade availability is different for assignments of all assignables' do
        it 'returns :on_grading' do
          allow(assignable_1).to receive(:grade_availability).and_return(:some_value)
          allow(assignable_2).to receive(:grade_availability).and_return(:another_value)
          expect(presenter.assessment_grade_status).to eql :on_grading
        end
      end
    end

    describe "#assessment_release_date" do
      let(:section) { build_stubbed(:section, :time_zone => "Pacific Time (US & Canada)") }

      before do
        allow(@focus).to receive(:sections).and_return([section])
      end

      context 'when assessment availability date is the same for all assignments of all assignables' do
        it 'returns the common assessment availability date' do
          date = Time.now
          allow(assignable_1).to receive(:show_at).and_return(date)
          allow(assignable_2).to receive(:show_at).and_return(date)
          expect(presenter.assessment_release_date).to eql format_date_time(date, :date_time_selector_format, section.time_zone)
        end
      end

      context 'when assessment availability date is different for assignments of all assignables' do
        it 'returns an empty string' do
          date = Time.now
          allow(assignable_1).to receive(:show_at).and_return(date)
          allow(assignable_2).to receive(:show_at).and_return(nil)
          expect(presenter.assessment_release_date).to eql ""
        end
      end
    end

    describe "#assessment_grade_release_date" do
      let(:section) { build_stubbed(:section, :time_zone => "Pacific Time (US & Canada)") }

      before do
        allow(@focus).to receive(:sections).and_return([section])
      end

      context 'when assessment grade availability date is the same for all assignments of all assignables' do
        it 'returns the common assessment grade availability date' do
          date = Time.now
          allow(assignable_1).to receive(:grades_available_at).and_return(date)
          allow(assignable_2).to receive(:grades_available_at).and_return(date)
          expect(presenter.assessment_grade_release_date).to eql format_date_time(date, :date_time_selector_format, section.time_zone)
        end
      end

      context 'when assessment grade availability date is different for assignments of all assignables' do
        it 'returns an empty string' do
          allow(assignable_1).to receive(:grades_available_at).and_return(Time.now)
          allow(assignable_2).to receive(:grades_available_at).and_return(nil)
          expect(presenter.assessment_grade_release_date).to eql ""
        end
      end
    end

    describe "#assessment_password" do
      context 'when an activity assignment has assessment details' do
        it 'returns the current password' do
          assigned_assessment_detail = AssignedAssessmentDetail.new
          allow(assigned_assessment_detail).to receive(:password).and_return('test')
          allow(activity_assignment).to receive(:assigned_assessment_detail).and_return(assigned_assessment_detail)
          allow(assignable_1).to receive(:assignments).and_return([activity_assignment])
          expect(presenter.assessment_password).to eql 'test'
        end
      end
    end

    describe "#assessment_answer_release_date" do
      let(:section) {build_stubbed(:section, :time_zone => "Pacific Time (US & Canada)") }

      before do
        allow(@focus).to receive(:sections).and_return([section])
      end

      context 'when assessment answer availability date is the same for all assignments of all assignables' do
        it 'returns the common assessment answer availability date' do
          date = Time.now
          allow(assignable_1).to receive(:answers_available_at).and_return(date)
          allow(assignable_2).to receive(:answers_available_at).and_return(date)
          expect(presenter.assessment_answer_release_date).to eql format_date_time(date, :date_time_selector_format, section.time_zone)
        end
      end

      context 'when an activity assignment does not have assessment details' do
        it 'returns an empty string' do
          allow(activity_assignment).to receive(:assigned_assessment_detail).and_return(nil)
          allow(assignable_1).to receive(:assignments).and_return([activity_assignment])
          expect(presenter.assessment_password).not_to be_present
        end
      end
    end

    describe '#assessment_number_of_attempts' do
      context 'when an activity assignment has assessment details' do
        it 'returns the number of attempts' do
          assigned_assessment_detail = AssignedAssessmentDetail.new
          allow(assigned_assessment_detail).to receive(:number_of_attempts).and_return(6)
          allow(activity_assignment).to receive(:assigned_assessment_detail).and_return(assigned_assessment_detail)
          allow(assignable_1).to receive(:assignments).and_return([activity_assignment])

          expect(presenter.assessment_number_of_attempts).to eql 6
        end
      end

      context 'when an activity assignment does not have assessment details' do
        it 'returns an empty string' do
          assigned_assessment_detail = AssignedAssessmentDetail.new
          allow(activity_assignment).to receive(:assigned_assessment_detail).and_return(nil)
          allow(assignable_1).to receive(:assignments).and_return([activity_assignment])

          expect(presenter.assessment_number_of_attempts).to be_nil
        end
      end
    end

    describe '#attempts_overridable?' do
      let!(:activity_1) { create(:activity, activity_type: 'quiz') }
      let!(:activity_2) { create(:activity, activity_type: 'virtual_chat') }
      let(:section)    { create(:section) }
      let(:opts) { { :activity_ids => [],
          :resource_ids => [],
          :program_id => program.id } }

      before do
        allow(@focus).to receive(:sections).and_return([section])
        allow(@focus).to receive(:section).and_return(section)
      end

      context 'when activities do not have excluded types' do
        it 'returns true if user can override attempts' do
          prep_build_assignables([activity_1])

          presenter = InstructorAssignablesPresenter.new(@focus, opts)
          expect(presenter).to be_attempts_overridable
        end

        context 'when at least one activity is instructor graded' do
          it 'returns false' do
            allow(activity_2).to receive(:activity_type).and_return('fill_in_the_blanks')
            allow(activity_2).to receive(:instructor_graded?).and_return(true)
            prep_build_assignables([activity_1, activity_2])
            presenter = InstructorAssignablesPresenter.new(@focus, opts)
            expect(presenter).not_to be_attempts_overridable
          end
        end
      end

      context 'when activities have excluded types' do
        it 'returns false if user can not override attempts' do
          prep_build_assignables([activity_1, activity_2])
          presenter = InstructorAssignablesPresenter.new(@focus, opts)
          expect(presenter).not_to be_attempts_overridable

          allow(activity_1).to receive(:activity_type).and_return('composition')
          presenter = InstructorAssignablesPresenter.new(@focus, opts)
          expect(presenter).not_to be_attempts_overridable
        end
      end
    end

    describe '#number_of_attempts_warning' do
      context 'when user can override the number of attempts' do
        it 'returns nil' do
          allow(presenter).to receive(:attempts_overridable?).and_return(true)
          expect(presenter.number_of_attempts_warning).to be_nil
        end
      end

      context 'when user can not override the number of attempts' do
        it 'returns a custom message' do
          allow(presenter).to receive(:attempts_overridable?).and_return(false)
          expect(presenter.number_of_attempts_warning).to eq("Activities of type virtual chat, partner chat, and composition can only support one attempt.")
        end
      end
    end

    describe "#assessment_release_status_text" do
      let(:section) { build_stubbed(:section, :time_zone => "Pacific Time (US & Canada)") }

      before do
        allow(@focus).to receive(:sections).and_return([section])
      end

      context 'when assignables dont have assignments' do
        it "returns 'I release it'" do
          allow(assignable_1).to receive(:show_assessment).and_return(nil)
          allow(assignable_2).to receive(:show_assessment).and_return(nil)
          expect(presenter.assessment_release_status_text).to eql 'I release it'
        end
      end

      context 'when assessment release status is the same for all assignments of all assignables' do
        it 'returns the common assessment release status' do
          allow(assignable_1).to receive(:show_assessment).and_return('some_value')
          allow(assignable_2).to receive(:show_assessment).and_return('some_value')
          expect(presenter.assessment_release_status_text).to eql 'some_value'
        end
      end

      context 'when assessment release status is different for assignments of all assignables' do
        it "returns 'I release it'"  do
          allow(assignable_1).to receive(:show_assessment).and_return('some_value')
          allow(assignable_2).to receive(:show_assessment).and_return('another_value')
          expect(presenter.assessment_release_status_text).to eql 'I release it'
        end
      end
    end

    describe "#assessment_grade_status_text" do
      let(:section) { build_stubbed(:section, :time_zone => "Pacific Time (US & Canada)") }
      before do
        allow(@focus).to receive(:sections).and_return([section])
      end

      context 'when assignables dont have assignments' do
        it "returns 'when all students have been graded'" do
          allow(assignable_1).to receive(:grade_availability).and_return(nil)
          allow(assignable_2).to receive(:grade_availability).and_return(nil)
          expect(presenter.assessment_grade_status_text).to eql 'when all students have been graded'
        end
      end

      context 'when assessment release status is the same for all assignments of all assignables' do
        context "and is set to specific date" do
          before do
            allow(assignable_1).to receive(:grade_availability).and_return(:on_specific_date)
            allow(assignable_2).to receive(:grade_availability).and_return(:on_specific_date)
            @date = Time.now
          end

          context "and the specified date is the same for all asignments" do
            it 'returns the common grade release date in the correct format' do
              allow(assignable_1).to receive(:grades_available_at).and_return(@date)
              allow(assignable_2).to receive(:grades_available_at).and_return(@date)
              expect(presenter.assessment_grade_status_text).to eql format_date_time(@date, :abr_weekday_month_ordinal_with_time, section.time_zone)
            end
          end

          context "and the specified date is the varies for all asignments" do
            it 'returns an empty string' do
              allow(assignable_1).to receive(:grades_available_at).and_return(@date)
              allow(assignable_2).to receive(:grades_available_at).and_return(nil)
              expect(presenter.assessment_grade_status_text).to eql 'when I release them'
            end
          end
        end

        context "and is set to due date" do
          before do
            allow(assignable_1).to receive(:grade_availability).and_return(:on_due_date)
            allow(assignable_2).to receive(:grade_availability).and_return(:on_due_date)
            @date = Time.now
          end

          context "and the specified date is the same for all asignments" do
            it 'returns the common due date in the correct format' do
              allow(assignable_1).to receive(:due_date).and_return(@date)
              allow(assignable_2).to receive(:due_date).and_return(@date)
              expect(presenter.assessment_grade_status_text).to eql format_date_time(@date, :abr_weekday_month_ordinal_with_time, section.time_zone)
            end
          end

          context "and the specified date is the varies for all asignments" do
            it 'returns an empty string' do
              allow(assignable_1).to receive(:due_date).and_return(@date)
              allow(assignable_2).to receive(:due_date).and_return(nil)
              expect(presenter.assessment_grade_status_text).to eql 'when I release them'
            end
          end
        end

        context 'and is set to any other grade availability status' do
          it "returns the corresponding AVAILABILITY_OPTIONS constant value"  do
            allow(assignable_1).to receive(:grade_availability).and_return(:never)
            allow(assignable_2).to receive(:grade_availability).and_return(:never)
            expect(presenter.assessment_grade_status_text).to eql 'never'
          end
        end
      end

      context 'when assessment grade release status is different for assignments of all assignables' do
        it "returns 'when all students have been graded'"  do
          allow(assignable_1).to receive(:grade_availability).and_return(:never)
          allow(assignable_2).to receive(:grade_availability).and_return(:on_grading)
          expect(presenter.assessment_grade_status_text).to eql 'when all students have been graded'
        end
      end
    end

    describe "#current_due_time_time" do
      it "returns formatted time without zone" do
        date = Time.now
        allow(presenter).to receive(:current_due_time).and_return(date)
        expect(presenter.current_due_time_text).to eql date.strftime('%l:%M %p')
      end
    end

    describe "#current_due_time" do
      before do
        @date = Time.now
        @section_due_time = 15.day.ago.to_date
        allow(@focus).to receive(:section).and_return(double(Section, :due_time => @section_due_time))
      end

      context "when the specified due time is the same for all asignments" do
        it 'returns the common due time in the correct format' do
          allow(assignable_1).to receive(:due_time).and_return(@date)
          allow(assignable_2).to receive(:due_time).and_return(@date)
          expect(presenter.current_due_time).to eql @date
        end
      end

      context "when the specified due time is different for all asignments" do
        it "returns the current section's due time in the correct format" do
          allow(assignable_1).to receive(:due_time).and_return(@date)
          allow(assignable_2).to receive(:due_time).and_return(nil)
          expect(presenter.current_due_time).to eql @section_due_time
        end
      end

      context "when the due time varies between sections" do
        it "returns the current section's due time in the correct format" do
          allow(assignable_1).to receive(:due_time).and_return('varies')
          allow(assignable_2).to receive(:due_time).and_return('varies')
          expect(presenter.current_due_time).to eql @section_due_time
        end
      end
    end

    describe "#current_time_limit" do
      before do
        allow(assignable_1).to receive(:assignments).and_return(activity_assignment)
        allow(assignable_2).to receive(:assignments).and_return(activity_assignment_2)
      end
      context 'when the assignment has an assigned_assessment_detail' do
        context 'when the specified time_limit is the same for all assignments' do
          it "returns the common time limit in the correct format" do
            allow(activity_assignment).to receive(:assigned_assessment_detail).and_return(
              double(AssignedAssessmentDetail, :time_limit => 30))
            allow(activity_assignment_2).to receive(:assigned_assessment_detail).and_return(
              double(AssignedAssessmentDetail, :time_limit => 30))
            expect(presenter.current_time_limit).to eql(30)
          end
        end

        context 'when the specified time_limit is not the same for all assignments' do
          it "returns 0" do
            allow(activity_assignment).to receive(:assigned_assessment_detail).and_return(
              double(AssignedAssessmentDetail, :time_limit => 30))
            allow(activity_assignment_2).to receive(:assigned_assessment_detail).and_return(
              double(AssignedAssessmentDetail, :time_limit => 45))
            expect(presenter.current_time_limit).to eql(0)
          end
        end
      end

      context 'when any number of assignments do not have an assigned_assessment_detail' do
        it "returns 0" do
            allow(activity_assignment).to receive(:assigned_assessment_detail).and_return(nil)
            allow(activity_assignment_2).to receive(:assigned_assessment_detail).and_return(
              double(AssignedAssessmentDetail, :time_limit => 45))
            expect(presenter.current_time_limit).to eql(0)
        end
      end

      context 'when there are no assignments' do
        it 'returns 0' do
          presenter.assignables = []
          expect(presenter.current_time_limit).to be_zero
        end
      end
    end
  end

  describe "#sentence_text_with_singular_label" do
    let(:presenter) { InstructorAssignablesPresenter.new(@focus, @opts) }

    before do
      allow(toc_entry).to receive(:singular_label).and_return("quiz")
      allow(lesson).to receive(:strand_for_toc_location).and_return(toc_entry)
      allow(activity).to receive(:lesson).and_return(lesson)
    end

    context "when assignable type vary" do
      before do
        allow(@focus).to receive(:sections).and_return(sections)
        allow(activity_2).to receive(:lesson).and_return(lesson)
        prep_build_assignables([activity, activity_2])
        allow(Resource).to receive(:find).and_return([resource])
      end

      context "for show_assessment field" do
        it "returns default text", test_debt: true do
          pending 'jquintero - need to fix stubs here'
          expect(presenter.sentence_text_with_singular_label(:show_assessment)).to eql "The assessment will be hidden until"
        end
      end

      context "for custom_due_time field" do
        it "returns default text", test_debt: true do
          pending 'jquintero - need to fix stubs here'
          expect(presenter.sentence_text_with_singular_label(:custom_due_time)).to eql "The assessment will be due at"
        end
      end

      context 'for time_limit field' do
        it "returns default text" do
          expect(presenter.sentence_text_with_singular_label(:time_limit)).to eql "Set a time limit (minutes)"
        end
      end

      context 'for password field' do
        it "returns default text" do
          expect(presenter.sentence_text_with_singular_label(:password)).to eql "Set a password"
        end
      end
    end

    context "when assignables are activities" do
      context "and they have the same singular label" do
        before do
          allow(@focus).to receive(:sections).and_return(sections)
          allow(activity_2).to receive(:lesson).and_return(lesson)
          prep_build_assignables([activity, activity_2])
          allow(Resource).to receive(:find).and_return([])
        end

        context "for show_assessment field" do
          it "returns correct text with the common singular label" do
            expect(presenter.sentence_text_with_singular_label(:show_assessment)).to eql "The quiz will be hidden until"
          end
        end

        context "for custom_due_time field" do
          it "returns correct text with the common singular label" do
            expect(presenter.sentence_text_with_singular_label(:custom_due_time)).to eql "The quiz will be due at"
          end
        end
      end

      context "and they don't have the same singular label" do
        before do
          allow(@focus).to receive(:sections).and_return(sections)
          allow(toc_entry).to receive(:singular_label).and_return("quiz")
          allow(toc_entry_2).to receive(:singular_label).and_return("exam")
          allow(lesson).to receive(:strand_for_toc_location).and_return(toc_entry)
          allow(lesson_2).to receive(:strand_for_toc_location).and_return(toc_entry_2)
          allow(activity_2).to receive(:lesson).and_return(lesson_2)
          prep_build_assignables([activity, activity_2])
          allow(Resource).to receive(:find).and_return([])
        end

        context "for show_assessment field" do
          it "returns default text" do
            expect(presenter.sentence_text_with_singular_label(:show_assessment)).to eql "The assessment will be hidden until"
          end
        end

        context "for custom_due_time field" do
          it "returns default text" do
            expect(presenter.sentence_text_with_singular_label(:custom_due_time)).to eql "The assessment will be due at"
          end
        end
      end
    end
  end

  describe '#assessment_grade_availability_options' do
    let(:presenter) { InstructorAssignablesPresenter.new(@focus, @opts) }

    before do
      prep_build_assignables([build_stubbed(:activity)])
      allow(Assignment).to receive_message_chain(:by_activities_and_sections, :group_by).and_return({})
    end

    it "should return the grade availability options with a structure suited to build a dropdown ['Description', :value]" do
      expect(presenter.assessment_grade_availability_options).to be_a Array
      expect(presenter.assessment_grade_availability_options.first).to be_a Array
      expect(presenter.assessment_grade_availability_options.first.size).to eql 2
      expect(presenter.assessment_grade_availability_options.first[0]).to be_a String
      expect(presenter.assessment_grade_availability_options.first[1]).to be_a Symbol
    end

    it "should return the grade availability options in the given order" do
      expect(presenter.assessment_grade_availability_options.size).to eql 5
      expect(presenter.assessment_grade_availability_options[0]).to eq(['when all students have been graded', :on_grading])
      expect(presenter.assessment_grade_availability_options[1]).to eq(['when I release them', :on_release])
      expect(presenter.assessment_grade_availability_options[2]).to eq(['after a specific date and time', :on_specific_date])
      expect(presenter.assessment_grade_availability_options[3]).to eq(['after the due time', :on_due_date])
      expect(presenter.assessment_grade_availability_options[4]).to eq(['never', :never])
    end
  end

  describe '#update_assignments_path' do
    let(:presenter) { presenter = InstructorAssignablesPresenter.new(@focus, @opts) }

    context 'when managing activities' do
      before do
        allow(Assignment).to receive_message_chain(:by_activities_and_sections, :group_by).and_return({})
        prep_build_assignables([build_stubbed(:activity)])
      end

      it 'returns the update activity assignments path' do
        expect(presenter).to receive(:update_activity_assignments_path).with(presenter.program_id).and_return('foo')
        expect(presenter.update_assignments_path).to eql 'foo'
      end
    end
  end

  describe '#pluralize_assignable_type' do
    let(:presenter) { InstructorAssignablesPresenter.new(@focus, @opts) }
    let(:assignable) { double(InstructorAssignablesPresenter::Assignable, :activity? => false) }

    before do
      prep_build_assignables
      allow(Assignment).to receive_message_chain(:by_activities_and_sections, :group_by).and_return({})

      # Because we need both the singular and plural available to the UI,
      # the method signature is changed to accept an integer.
      # The number of assignables is no longer significant to this method;
      # we need only one to provide the label or class name.
      presenter.assignables << assignable

      allow(assignable).to receive(:class_name).and_return('foo')
    end

    context 'with one assignable' do
      context "when assignable does not have an assignable_label" do
        before { allow(assignable).to receive(:assignable_label).and_return(nil) }

        it 'returns the pluralized class name of the first assignable' do
          expect(presenter.pluralized_assignable_type(1)).to eql 'foo'
        end
      end

      context "when assignable has an assignable_label" do
        let(:assignable_label) { 'exam' }
        before do
          allow(assignable).to receive(:assignable_label).and_return(assignable_label)
          allow(assignable).to receive(:activity?).and_return(true)
        end

        it 'returns the assignable label in singular' do
          expect(presenter.pluralized_assignable_type(1)).to eql 'exam'
        end
      end
    end

    context 'with multiple assignables' do
      context "when assignables do not have an assignable_label" do
        it 'returns the pluralized class name of the first assignable' do
          expect(presenter.pluralized_assignable_type(2)).to eql 'foos'
        end
      end

      context "when assignables have an assignable_label" do
        let(:assignable_label) { 'exam' }
        before do
          allow(assignable).to receive(:assignable_label).and_return(assignable_label)
          allow(assignable).to receive(:activity?).and_return(true)
        end

        it 'returns the pluralized assignable_label of the first assignable' do
          expect(presenter.pluralized_assignable_type(2)).to eql 'exams'
        end
      end
    end
  end

  context 'always' do
    before do
      prep_build_assignables([build_stubbed(:activity)])
      allow(Assignment).to receive_message_chain(:by_activities_and_sections, :group_by).and_return({})
      @presenter = InstructorAssignablesPresenter.new(@focus, @opts)
    end

    describe "#already_assigned_count" do
      it "returns the number of already assigned activities" do
        assignments = [build_stubbed(:assignment)]
        assignable = InstructorAssignablesPresenter::Assignable.new(build_stubbed(:activity), assignments)
        allow(@presenter).to receive(:assignables).and_return([assignable])
        expect(@presenter.already_assigned_count).to eql 1
      end
    end

    describe '#assignables_count' do
      it 'returns the number of activities' do
        expect(@presenter.assignables_count).to eql 1
      end
    end

    describe '#course_name' do
      it 'returns the course name from the focus' do
        allow(@focus).to receive(:course_name).and_return('Course 1')
        expect(@presenter.course_name).to eql 'Course 1'
      end
    end

    describe '#section_names' do
      it 'returns the focused section names' do
        allow(@focus).to receive(:section_names).and_return(['Section 1', 'Section 2'])
        expect(@presenter.section_names).to eql 'Section 1, Section 2'
      end
    end

    describe '#track_group_names' do
      let(:track_group_1) { create(:track_group, :program => program) }

      it 'returns list of track group names' do
        track_group_1
        expect(@presenter.track_group_names).to include track_group_1.name
      end
    end

    describe '#categories' do
      let(:assessment_category) { create(:category) }
      let(:non_assessment_category) { create(:category) }

      context "with assessment assignables" do
        xit 'returns the assessment only categories for the focused course', test_debt: true do
          allow(@presenter).to receive(:has_assessments?).and_return(true)
          course = create(:course)
          course.categories << assessment_category
          course.categories << non_assessment_category
          allow(@focus).to receive(:course).and_return(course)
          expect(@presenter.categories).to eq([assessment_category])
        end
      end

      context "with non-assessment assignables" do
        it 'returns the assessment and non-assessment categories' do
          allow(@presenter).to receive(:has_assessments?).and_return(false)
          course = create(:course)
          course.categories << assessment_category
          course.categories << non_assessment_category
          allow(@focus).to receive(:course).and_return(course)
          expect(@presenter.categories).to include assessment_category
          expect(@presenter.categories).to include non_assessment_category
        end
      end

      context "with assessment and non-assessment assignables" do
        xit 'returns the assessment only categories for the focused course', test_debt: true do
          allow(@presenter).to receive(:has_assessments?).and_return(true)
          course = create(:course)
          course.categories << assessment_category
          course.categories << non_assessment_category
          allow(@focus).to receive(:course).and_return(course)
          expect(@presenter.categories).to eq([assessment_category])
        end
      end
    end

    describe '#current_category_id', test_debt: true do
      context 'when all selected activities are currently assigned to the same category' do
        it 'returns a category id', test_debt: true
      end

      context 'when any selected activities are assigned to differeing categories' do
        it 'returns nil', test_debt: true
      end

      context 'when any selected activities are not yet assigned' do
        it 'returns nil', test_debt: true
      end
    end

    describe '#has_assessments?' do
      context 'when an assignable is an assessment activity' do
        before do
          @presenter.assignables = [
            double(InstructorAssignablesPresenter::Assignable, :assessment? => false),
            double(InstructorAssignablesPresenter::Assignable, :assessment? => true),
            double(InstructorAssignablesPresenter::Assignable, :assessment? => false)
          ]
        end

        it 'returns true' do
          expect(@presenter.has_assessments?).to be_truthy
        end
      end

      context 'when no assignables are assessment activities' do
        before do
          @presenter.assignables = [
            double(InstructorAssignablesPresenter::Assignable, :assessment? => false),
            double(InstructorAssignablesPresenter::Assignable, :assessment? => false),
            double(InstructorAssignablesPresenter::Assignable, :assessment? => false)
          ]
        end

        it 'returns false' do
          expect(@presenter.has_assessments?).to be_falsey
        end
      end
    end

    describe '#refine_selection?' do
      context 'when initialized with source = calendar' do
        before do
          @presenter = InstructorAssignablesPresenter.new(@focus, @opts.merge(:source => 'calendar') )
        end

        it 'returns true' do
          expect(@presenter.refine_selection?).to be_truthy
        end
      end

      context 'when initialized with source = toc' do
        before do
          @presenter = InstructorAssignablesPresenter.new(@focus, @opts.merge(:source => 'toc') )
        end

        it 'returns false' do
          expect(@presenter.refine_selection?).to be_falsey
        end
      end

      context 'when not initialized with a source' do
        before do
          @presenter = InstructorAssignablesPresenter.new(@focus, @opts)
        end

        it 'returns false' do
          expect(@presenter.refine_selection?).to be_falsey
        end
      end
    end
  end

  context 'when none of the selected activities are already assigned' do
    before do
      prep_build_assignables([build_stubbed(:activity)])
      allow(Assignment).to receive_message_chain(:by_activities_and_sections, :group_by).and_return({})
      @presenter = InstructorAssignablesPresenter.new(@focus, @opts)
    end

    describe '#start_on_review_step?' do
      it 'returns false' do
        expect(@presenter.start_on_review_step?).to be_falsey
      end
    end

    describe '#start_on_reassign_step?' do
      it 'returns true' do
        expect(@presenter.start_on_reassign_step?).to be_truthy
      end
    end

    describe '#any_activities_already_assigned?' do
      it 'returns false' do
        expect(@presenter.any_activities_already_assigned?).to be_falsey
      end
    end

    describe '#group_chat_activities_count' do
      it 'returns 0' do
        expect(@presenter.group_chat_activities_count).to eql(0)
      end
    end
  end

  context 'when some of the activity is group chat' do
    before do
      prep_build_assignables([build_stubbed(:activity)])
      allow(Assignment).to receive_message_chain(:by_activities_and_sections, :group_by).and_return({})
      gchat_activity = create(
        :activity,
        activity_type: 'group_chat'
      )
      @presenter = InstructorAssignablesPresenter.new(@focus, @opts)
      @presenter.assignables.push(InstructorAssignablesPresenter::Assignable.new(gchat_activity))
    end

    describe '#group_chat_activities_count' do
      it 'returns 1' do
        expect(@presenter.group_chat_activities_count).to eql(1)
      end
    end
  end

  context 'when any of the selected activities are already assigned' do
    before do
      activity = build_stubbed(:activity)
      prep_build_assignables([activity])
      allow(Assignment).to receive_message_chain(:by_activities_and_sections, :group_by).and_return({ activity => [build_stubbed(:assignment)] })
      @presenter = InstructorAssignablesPresenter.new(@focus, @opts)
    end

    describe '#start_on_review_step?' do
      it 'returns true' do
        expect(@presenter.start_on_review_step?).to be_truthy
      end
    end

    describe '#start_on_reassign_step?' do
      it 'returns false' do
        expect(@presenter.start_on_reassign_step?).to be_falsey
      end
    end

    describe '#any_activities_already_assigned?' do
      it 'returns true' do
        expect(@presenter.any_activities_already_assigned?).to be_truthy
      end
    end
  end

  context 'with activities and assignments' do
    before do
      activity_1 = build_stubbed(:activity)
      activity_2 = build_stubbed(:activity)
      @activities = [activity_1, activity_2]
      prep_build_assignables(@activities)

      @assignments = { activity_1 => [build_stubbed(:assignment)], activity_2 => [build_stubbed(:assignment)] }
      allow(Assignment).to receive_message_chain(:by_activities_and_sections, :group_by).and_return(@assignments)

      @presenter = InstructorAssignablesPresenter.new(@focus, @opts)
    end

    describe '#selected_activity_ids' do
      before do
        @presenter.assignables = [
          double(InstructorAssignablesPresenter::Assignable, :class_name => 'activity', :id => 111, :assignment_ids => '333,444'),
          double(InstructorAssignablesPresenter::Assignable, :class_name => 'activity', :id => 222, :assignment_ids => '555')
        ]
      end

      it 'returns a comma separated string of activity ids' do
        expect(@presenter.selected_activity_ids).to eql '111,222'
      end
    end

    describe '#selected_resource_ids' do
      before do
        @presenter.assignables = [
          double(InstructorAssignablesPresenter::Assignable, :class_name => 'resource', :id => 567, :assignment_ids => '333,444'),
          double(InstructorAssignablesPresenter::Assignable, :class_name => 'resource', :id => 890, :assignment_ids => '555')
        ]
      end

      it 'returns a comma separated string of resource ids' do
        expect(@presenter.selected_resource_ids).to eql '567,890'
      end
    end
  end

  context 'when given a program id' do
    it 'sets and exposes the program id' do
      prep_build_assignables([build_stubbed(:activity)])
      allow(Assignment).to receive_message_chain(:by_activities_and_sections, :group_by).and_return({})
      @presenter = InstructorAssignablesPresenter.new(@focus, @opts)
      expect(@presenter.program_id).to eql @opts[:program_id]
    end
  end

  context 'when not given a program id' do
    it 'raises an error', test_debt: true do
      skip "Fix this: it raises an error because the section_id is missing, not because of program_id"
      @opts.delete(:program_id)
      expect { InstructorAssignablesPresenter.new(@focus, @opts) }
        .to raise_error(StandardError, "placeholder")
    end
  end

  describe "#has_preferred_assignment_date?" do
    let(:presenter) { InstructorAssignablesPresenter.new(@focus, @opts)}

    before do
      prep_build_assignables
      allow(Assignment).to receive_message_chain(:by_activities_and_sections, :group_by).and_return({})
    end

    it "returns true if prefer_assignment_date is not blank" do
      allow(presenter).to receive(:preferred_assignment_date).and_return(Date.today)
      expect(presenter).to be_has_preferred_assignment_date
    end

    it "returns false if prefer_assignment_date is ''" do
      allow(presenter).to receive(:preferred_assignment_date)
      expect(presenter).not_to be_has_preferred_assignment_date
    end
  end

  describe '#show_randomize_per_student_option?' do
    let(:instructor) { create(:instructor) }
    let(:course) { create(:course, owner: instructor) }
    let!(:section) { create(:section, instructor: instructor, course: course) }
    let(:activities) do
      [
        create(:activity, randomizable: false),
        create(:activity, randomizable: false)
      ]
    end
    let(:focus) do
      Focus.new(
        instructor,
        program,
        program.id.to_s => {
          'course_id' => course.id
        }
      )
    end
    let(:presenter) do
      described_class.new(
        focus,
        activity_ids: activities.map(&:id),
        resource_ids: [],
        program_id: program.id
      )
    end

    context 'when the program does not allow assessment randomization' do
      before do
        allow(program).to receive(:allow_assessments_randomization?).and_return(false)
      end

      it 'returns false' do
        expect(presenter.show_randomize_per_student_option?).to be_falsey
      end
    end

    context 'when the program allows assessment randomization' do
      before do
        allow(program).to receive(:allow_assessments_randomization?).and_return(true)
      end

      context 'when no assignable is randomizable' do
        it 'returns false' do
          expect(presenter.show_randomize_per_student_option?).to be_falsey
        end
      end

      context 'when at least one of the assignables is randomizable' do
        let(:activities) do
          [
            create(:activity, randomizable: false),
            create(:activity, randomizable: true)
          ]
        end

        it 'returns true' do
          expect(presenter.show_randomize_per_student_option?).to be_truthy
        end
      end
    end
  end

  describe 'assessment_randomize_per_student' do
    let(:instructor) { create(:instructor) }
    let(:course) { create(:course, owner: instructor) }
    let(:section_1) { create(:section, instructor: instructor, course: course) }
    let(:section_2) { create(:section, instructor: instructor, course: course) }
    let(:activity_1) { create(:activity, randomizable: false) }
    let(:activity_2) { create(:activity, randomizable: true) }
    let(:activities) { [activity_1, activity_2] }
    let(:focus) do
      Focus.new(
        instructor,
        program,
        program.id.to_s => {
          'course_id' => course.id
        }
      )
    end
    let(:presenter) do
      described_class.new(
        focus,
        activity_ids: activities.map(&:id),
        resource_ids: [],
        program_id: program.id
      )
    end

    context 'when no assignment has the randomize per student option set' do
      it 'returns false' do
        create(:assignment, assignable: activity_1, section: section_1)
        create(:assignment, assignable: activity_1, section: section_2)
        create(:assignment, assignable: activity_2, section: section_1)

        expect(presenter.assessment_randomize_per_student).to eq(false)
      end
    end

    context 'when not all the assignments have the same randomize per student ' \
            'option value' do
      it 'returns nil' do
        create(:assignment, assignable: activity_1, section: section_1, randomize_per_student: false)
        create(:assignment, assignable: activity_1, section: section_2, randomize_per_student: true)
        create(:assignment, assignable: activity_2, section: section_1)

        expect(presenter.assessment_randomize_per_student).to eq(nil)
      end
    end

    context 'when all assignments have the randomize per student option false' do
      it 'returns false' do
        create(:assignment, assignable: activity_1, section: section_1, randomize_per_student: false)
        create(:assignment, assignable: activity_1, section: section_2, randomize_per_student: false)
        create(:assignment, assignable: activity_2, section: section_1, randomize_per_student: false)

        expect(presenter.assessment_randomize_per_student).to eq(false)
      end
    end

    context 'when all assignments have the randomize per student option true' do
      it 'returns true' do
        create(:assignment, assignable: activity_1, section: section_1, randomize_per_student: true)
        create(:assignment, assignable: activity_1, section: section_2, randomize_per_student: true)
        create(:assignment, assignable: activity_2, section: section_1, randomize_per_student: true)

        expect(presenter.assessment_randomize_per_student).to eq(true)
      end
    end

    context 'when some activities have the same randomize per student option ' \
            'value in all the assignments and some activities have different ' \
            'randomize per student option value in their assignments' do
      it 'returns varies' do
        create(:assignment, assignable: activity_1, section: section_1, randomize_per_student: false)
        create(:assignment, assignable: activity_1, section: section_2, randomize_per_student: true)
        create(:assignment, assignable: activity_2, section: section_1, randomize_per_student: true)
        create(:assignment, assignable: activity_2, section: section_2)

        expect(presenter.assessment_randomize_per_student).to eq('varies')
      end
    end
  end

  describe 'due_dates_for_sections' do
    let(:instructor) { create(:instructor) }
    let(:course) { create(:course, owner: instructor) }
    let!(:section_1) { create(:section, instructor: instructor, course: course) }
    let!(:section_2) { create(:section, instructor: instructor, course: course) }
    let(:activity_1) { create(:activity) }
    let(:activity_2) { create(:activity) }
    let(:activities) { [activity_1, activity_2] }

    let(:current_focus) do
      Focus.new(
        instructor,
        program,
        program.id.to_s => {
          'course_id' => course.id
        }
      )
    end

    let(:presenter) do
      described_class.new(
        current_focus,
        activity_ids: activities.map(&:id),
        resource_ids: [],
        program_id: program.id
      )
    end

    context 'when there are not assignment sets manually ordered' do
      it 'returns an empty list' do
        expect(presenter.due_dates_for_sections).to eq([])
      end
    end

    context 'when there are assignment sets manually ordered' do
      before do
        AssignmentSet.create(
          section: section_1,
          due_date: section_1.course_end_date - 1.day
        )
        AssignmentSet.create(
          section: section_2,
          due_date: section_2.course_end_date - 2.days
        )
      end

      it 'returns a list of unique dates in dd-mm-yyyy format for the sections on focus' do
        expect(presenter.due_dates_for_sections).to eq(
          [(course.end_date - 1.day).strftime('%m/%d/%Y').to_s,
           (course.end_date - 2.days).strftime('%m/%d/%Y').to_s]
        )
      end
    end
  end

  describe '#in_institution_admin?' do
    subject(:presenter) { described_class.new(@focus, params) }

    before do
      prep_build_assignables
      allow(Assignment).to receive_message_chain(:by_activities_and_sections, :group_by)
        .and_return({})
    end

    context 'when not in institution admin' do
      let(:params) { @opts }

      it { expect(presenter.in_institution_admin?).to be false }
    end

    context 'when in institution admin' do
      let(:params) { @opts.merge(in_institution_admin: 'true') }

      it { expect(presenter.in_institution_admin?).to be true }
    end
  end

  describe InstructorAssignablesPresenter::Assignable do
    before do
      @activity = build_stubbed(:activity, :title => 'foo')
      @assignment = build_stubbed(:assignment, :due_date => '2012-04-01')
      @focus = double(Focus).as_null_object
    end

    describe '#title' do
      it 'returns the activity title' do
        activity_assignment = InstructorAssignablesPresenter::Assignable.new(@activity)
        expect(activity_assignment.title).to eql @activity.title
      end
    end

    describe "#strand_and_title_label" do
      it "returns the strand name and activity title" do
        allow(@activity).to receive(:strand_and_title_label).and_return('strand and title test label')
        activity = InstructorAssignablesPresenter::Assignable.new(@activity)
        expect(activity.strand_and_title_label).to eql 'strand and title test label'
      end
    end

    describe '#name' do
      it 'returns the assignable type and id' do
        assignable = InstructorAssignablesPresenter::Assignable.new(@activity)
        expect(assignable.name).to eql "activity_#{@activity.id}"
      end
    end

    describe '#class_name' do
      it 'returns an underscored string of the assignable class' do
        assignable = InstructorAssignablesPresenter::Assignable.new(build_stubbed(:activity) )
        expect(assignable.class_name).to eql 'activity'

        assignable = InstructorAssignablesPresenter::Assignable.new(build_stubbed(:resource) )
        expect(assignable.class_name).to eql 'resource'
      end
    end

    describe '#group_chat?' do
      it 'returns true as the assignable activity is group_chat' do
        assignable = InstructorAssignablesPresenter::Assignable.new(build_stubbed(:activity, activity_type: 'group_chat') )
        expect(assignable.group_chat?).to be_truthy
      end

      it 'returns false as the assignable activity is not group_chat' do
        assignable = InstructorAssignablesPresenter::Assignable.new(build_stubbed(:activity) )
        expect(assignable.group_chat?).to be_falsey
      end
    end

    describe '#group_chat_config' do
      it 'returns content object configuration if group chat assignment config record not available' do
        content_object = instance_double(
          MaestroActivityEngine::ActivityContent::GroupChatContent,
          min_students_selection: 2,
          max_students_selection: 5
        )
        gchat_activity = build_stubbed(:activity, activity_type: 'group_chat')
        assignable = InstructorAssignablesPresenter::Assignable.new(
          gchat_activity,
          [build_stubbed(:assignment)]
        )
        allow(gchat_activity).to receive(:content_object).and_return(content_object)
        expect(assignable.group_chat_config[:group_minimum]). to eql(3)
        expect(assignable.group_chat_config[:group_maximum]). to eql(6)
      end
    end

    describe '#id' do
      it 'returns the id of the assignable' do
        assignable = InstructorAssignablesPresenter::Assignable.new(@activity)
        expect(assignable.id).to eql @activity.id
      end
    end

    describe '#assignment_ids' do
      it 'returns a comma separated string of assignment ids' do
        assignments = [build_stubbed(:assignment), build_stubbed(:assignment)]
        assignable = InstructorAssignablesPresenter::Assignable.new(@activity, assignments)
        expect(assignable.assignment_ids).to eql "#{assignments.first.id},#{assignments.last.id}"
      end
    end

    describe '#has_assignments?' do
      context 'when it has assignments' do
        before do
          assignments = [build_stubbed(:assignment), build_stubbed(:assignment)]
          @assignable = InstructorAssignablesPresenter::Assignable.new(@activity, assignments)
        end

        it 'returns true' do
          expect(@assignable.has_assignments?).to be_truthy
        end
      end

      context 'when does not have assignments' do
        before do
          @assignable = InstructorAssignablesPresenter::Assignable.new(@activity)
        end

        it 'returns false' do
          expect(@assignable.has_assignments?).to be_falsey
        end
      end
    end

    describe '#activity?' do
      context 'when the assignable is an activity' do
        before do
          @assignable = InstructorAssignablesPresenter::Assignable.new(build_stubbed(:activity) )
        end

        it 'returns true' do
          expect(@assignable.activity?).to be_truthy
        end
      end

      context 'when the assignable is not an activity' do
        before do
          @assignable = InstructorAssignablesPresenter::Assignable.new(build_stubbed(:resource) )
        end

        it 'returns false' do
          expect(@assignable.activity?).to be_falsey
        end
      end
    end

    describe '#resource?' do
      context 'when the assignable is a resource' do
        before do
          @assignable = InstructorAssignablesPresenter::Assignable.new(build_stubbed(:resource) )
        end

        it 'returns true' do
          expect(@assignable.resource?).to be_truthy
        end
      end

      context 'when the assignable is not a resource' do
        before do
          @assignable = InstructorAssignablesPresenter::Assignable.new(build_stubbed(:activity) )
        end

        it 'returns false' do
          expect(@assignable.resource?).to be_falsey
        end
      end
    end

    describe '#assessment?' do
      context 'when the assignable responds to assessment?' do
        before do
          @assignable = build_stubbed(:activity)
        end

        context 'when the assignable is an assessment' do
          before do
            allow(@assignable).to receive(:assessment?).and_return(true)
            @presenter_assignable = InstructorAssignablesPresenter::Assignable.new(@assignable)
          end

          it 'returns true' do
            expect(@presenter_assignable.assessment?).to be_truthy
          end
        end

        context 'when the assignable is not an assessment' do
          before do
            allow(@assignable).to receive(:assessment?).and_return(false)
            @presenter_assignable = InstructorAssignablesPresenter::Assignable.new(@assignable)
          end

          it 'returns false' do
            expect(@presenter_assignable.assessment?).to be_falsey
          end
        end
      end

      context 'when the assignable does not respond to assessment?' do
        before do
          @assignable = build_stubbed(:resource)
          @presenter_assignable = InstructorAssignablesPresenter::Assignable.new(@assignable)
        end

        it 'returns false' do
          expect(@presenter_assignable.assessment?).to be_falsey
        end
      end
    end

    describe 'assignable_label' do
      context 'when the assignable responds to strand_singular_label' do
        let(:assignable) { build_stubbed(:activity) }

        it 'returns the assignable strand_singular label' do
          allow(assignable).to receive(:strand_singular_label).and_return('exam')
          presenter_assignable = InstructorAssignablesPresenter::Assignable.new(assignable)
          expect(presenter_assignable.assignable_label).to eql 'exam'
        end
      end

      context 'when the assignable does not respond to strand_singular_label' do
        let(:assignable) { build_stubbed(:resource) }

        it 'return nil' do
          presenter_assignable = InstructorAssignablesPresenter::Assignable.new(assignable)
          expect(presenter_assignable.assignable_label).to be_nil
        end
      end
    end

    COMMON_ATTRIBUTES = %i[
      category_id
      due_time
      grade_availability
      grades_available_at
      randomize_per_student
      show_assessment
      show_at
      time_limit
    ]

    COMMON_ATTRIBUTES.each do |attribute|
      describe "##{attribute.to_s}" do
        context 'with an assignment' do
          it "returns the assignment #{attribute.to_s}" do
            allow(activity_assignment).to receive(attribute).and_return(:value1)
            assignable = InstructorAssignablesPresenter::Assignable.new(activity, [activity_assignment])
            expect(assignable.send(attribute)).to eql :value1
          end
        end

        context 'with multiple assignments' do
          context "when the #{attribute.to_s} are the same between the assignments" do
            it "returns the #{attribute.to_s}" do
              allow(activity_assignment).to receive(attribute).and_return(:value1)
              allow(activity_assignment_2).to receive(attribute).and_return(:value1)
              assignable = InstructorAssignablesPresenter::Assignable.new(activity, [activity_assignment, activity_assignment_2])
              expect(assignable.send(attribute)).to eql :value1
            end
          end

          context "when the #{attribute.to_s} differ between the assignments" do
            it "returns 'varies'" do
              allow(activity_assignment).to receive(attribute).and_return(:value1)
              allow(activity_assignment_2).to receive(attribute).and_return(:value2)
              assignable = InstructorAssignablesPresenter::Assignable.new(activity, [activity_assignment, activity_assignment_2])
              expect(assignable.send(attribute)).to eql 'varies'
            end
          end
        end

        context 'with no assignment' do
          it 'returns nil' do
            assignable = InstructorAssignablesPresenter::Assignable.new(activity)
            expect(assignable.send(attribute)).to be_nil
          end
        end
      end
    end

    describe '#unassigned_sections' do
      it "should return all unassigned sections" do
        section_1 = build_stubbed(:section)
        section_2 = build_stubbed(:section)
        assignment_1 = build_stubbed(:assignment , :section => section_1)
        allow(assignment_1).to receive(:all_sections_in_course).and_return([section_1,section_2])
        assignable = InstructorAssignablesPresenter::Assignable.new(@activity, [assignment_1])
        expect(assignable.unassigned_sections).to eql([section_2])
      end
    end

    describe '#due_date' do
      context "when there are no assignments" do
        it 'should return empty string' do
          expect(InstructorAssignablesPresenter::Assignable.new(@activity, []).due_date).to be_blank
        end
      end

      context "when there are assignments" do
        context "when assignment have different categories" do
          it 'should return string "varies"' do
            assignable = InstructorAssignablesPresenter::Assignable.new(@activity, ['s1', 's2'])
            allow(assignable).to receive(:assignments_vary_by_due_date?).and_return(true)
            expect(assignable.due_date).to eql("varies")
          end
        end

        context "when assignments have same due date" do
          it 'should return common due date"' do
            assignment = build_stubbed(:assignment)
            allow(assignment).to receive(:due_date).and_return(Date.today)
            assignable = InstructorAssignablesPresenter::Assignable.new(@activity,[assignment])
            allow(assignable).to receive(:assignments_vary_by_due_date?).and_return(false)
            expect(assignable.toc_formatted_due_date).to eql(format_date_time(Date.today, :toc_due_date))
          end
        end
      end
    end

    describe '#track_group_name' do
      context "when there are no assignments" do
        it 'should return empty string' do
          expect(InstructorAssignablesPresenter::Assignable.new(@activity, []).track_group_name).to be_blank
        end
      end

      context "when there are assignments" do
        context "when assignment have different track groups" do
          it 'should return string "varies"' do
            assignable = InstructorAssignablesPresenter::Assignable.new(@activity, ['s1', 's2'])
            allow(assignable).to receive(:assignments_vary_by_track_group_name?).and_return(true)
            expect(assignable.track_group_name).to eql("varies")
          end
        end

        context "when assignments have same track_group" do
          it 'should return common track_group name"' do
            assignment = build_stubbed(:assignment)
            track_group = build_stubbed(:track_group)
            allow(assignment).to receive(:track_group).and_return(track_group)
            assignable = InstructorAssignablesPresenter::Assignable.new(@activity,[assignment])
            allow(assignable).to receive(:assignments_vary_by_track_group_name?).and_return(false)
            expect(assignable.track_group_name).to eql(track_group.name)
          end
        end
      end
    end

    describe '#category_name' do
      context "when there are no assignments" do
        it 'should return empty string' do
          expect(InstructorAssignablesPresenter::Assignable.new(@activity, []).category_name).to be_blank
        end
      end

      context "when there are assignments" do
        context "when assignment have different categories" do
          it 'should return string "varies"' do
            assignable = InstructorAssignablesPresenter::Assignable.new(@activity, ['s1', 's2'])
            allow(assignable).to receive(:assignments_vary_by_category?).and_return(true)
            expect(assignable.category_name).to eql("varies")
          end
        end

        context "when assignments have same category" do
          it 'should return common category name"' do
            assignment = build_stubbed(:assignment)
            category = build_stubbed(:category)
            allow(assignment).to receive(:category).and_return(category)
            assignable = InstructorAssignablesPresenter::Assignable.new(@activity,[assignment])
            allow(assignable).to receive(:assignments_vary_by_category?).and_return(false)
            expect(assignable.category_name).to eql(category.name)
          end
        end
      end
    end

    describe '#different_assignment_counts_by_section?' do
      before do
        assignments = [
          double(Assignment, :due_date => 'foo', :category => 'baz'),
          double(Assignment, :due_date => 'foo', :category => 'baz'),
          double(Assignment, :due_date => 'foo', :category => 'baz')
        ]
        assignments.each {|assignment| allow(assignment).to receive(:sections_in_course_count).and_return(3) }
        @assignable = InstructorAssignablesPresenter::Assignable.new(@activity, assignments)
      end
      context "when focused on a section" do
        it "returns false" do
          @assignable.focused_on_only_one_section = true
          expect(@assignable).not_to be_different_assignment_counts_by_section
        end
      end
      context "when focused on a course" do
        context 'when an assignment is assigned in all sections' do
          it 'returns false' do
            expect(@assignable).not_to be_different_assignment_counts_by_section
          end
        end

        context 'when an assignment is assigned in some sections but not assigned in another section' do
          before do
            assignments = [
              double(Assignment, :due_date => 'foo', :category => 'baz'),
              double(Assignment, :due_date => 'foo', :category => 'baz')
            ]
            assignments.each {|assignment| allow(assignment).to receive(:sections_in_course_count).and_return(3) }
            @assignable = InstructorAssignablesPresenter::Assignable.new(@activity, assignments)
          end

          it 'returns true' do
            expect(@assignable).to be_different_assignment_counts_by_section
          end
        end
      end
    end

    describe '#assignments_vary_by_due_date?' do
      context 'when there are assignments with due date that are same' do
        before do
          assignments = [
            double(Assignment, :due_date => 'foo', :category => 'baz'),
            double(Assignment, :due_date => 'foo', :category => 'jaz'),
            double(Assignment, :due_date => 'foo', :category => 'baz')
          ]
          assignments.each {|assignment| allow(assignment).to receive(:sections_in_course_count).and_return(3) }
          @assignable = InstructorAssignablesPresenter::Assignable.new(@activity, assignments)
        end

        it 'returns false' do
          expect(@assignable).not_to be_assignments_vary_by_due_date
        end
      end

      context 'when there are assignments with due date that are different' do
        before do
          assignments = [
            double(Assignment, :due_date => 'foo', :category => 'baz'),
            double(Assignment, :due_date => 'bar', :category => 'baz'),
            double(Assignment, :due_date => 'foo', :category => 'baz')
          ]
          assignments.each {|assignment| allow(assignment).to receive(:sections_in_course_count).and_return(3) }
          @assignable = InstructorAssignablesPresenter::Assignable.new(@activity, assignments)
        end

        it 'returns true' do
          expect(@assignable).to be_assignments_vary_by_due_date
        end
      end
    end

    describe '#assignments_vary_by_category?' do
      context 'when there are assignments with category that are same' do
        before do
          assignments = [
            double(Assignment, :due_date => 'foo', :category => 'baz'),
            double(Assignment, :due_date => 'foo', :category => 'baz'),
            double(Assignment, :due_date => 'foo', :category => 'baz')
          ]
          assignments.each {|assignment| allow(assignment).to receive(:sections_in_course_count).and_return(3) }
          @assignable = InstructorAssignablesPresenter::Assignable.new(@activity, assignments)
        end

        it 'returns false' do
          expect(@assignable).not_to be_assignments_vary_by_category
        end
      end

      context 'when there are assignments with category that are different' do
        before do
          assignments = [
            double(Assignment, :due_date => 'foo', :category => 'baz'),
            double(Assignment, :due_date => 'foo', :category => 'bar'),
            double(Assignment, :due_date => 'foo', :category => 'baz')
          ]
          assignments.each {|assignment| allow(assignment).to receive(:sections_in_course_count).and_return(3) }
          @assignable = InstructorAssignablesPresenter::Assignable.new(@activity, assignments)
        end

        it 'returns true' do
          expect(@assignable).to be_assignments_vary_by_category
        end
      end
    end

    describe '#assignments_vary_by_section?' do
      context 'when a section has a due date that differs' do
        before do
          assignments = [
            double(Assignment, :due_date => 'foo', :category => 'baz'),
            double(Assignment, :due_date => 'bar', :category => 'baz'),
            double(Assignment, :due_date => 'foo', :category => 'baz')
          ]
          assignments.each {|assignment| allow(assignment).to receive(:sections_in_course_count).and_return(3) }
          @assignable = InstructorAssignablesPresenter::Assignable.new(@activity, assignments)
        end

        it 'returns true' do
          expect(@assignable.assignments_vary_by_section?).to be_truthy
        end
      end

      context 'when an assignment is assigned in some sections but not assigned in another section' do
        before do
          assignments = [
            double(Assignment, :due_date => 'foo', :category => 'baz'),
            double(Assignment, :due_date => 'foo', :category => 'baz')
          ]
          assignments.each {|assignment| allow(assignment).to receive(:sections_in_course_count).and_return(3) }
          allow(@focus).to receive(:focused_on_only_one_section?).and_return(false)
          @assignable = InstructorAssignablesPresenter::Assignable.new(@activity, assignments)
        end

        it 'returns true' do
          expect(@assignable.assignments_vary_by_section?).to be_truthy
        end
      end

      context 'when a section has a track groups that differs' do
        before do
          assignments = [
            double(Assignment, :due_date => 'foo', :category => 'bar', :track_group_name=>'t1'),
            double(Assignment, :due_date => 'foo', :category => 'bar', :track_group_name=>'t2'),
            double(Assignment, :due_date => 'foo', :category => 'bar', :track_group_name =>'t2')
          ]
          assignments.each {|assignment| allow(assignment).to receive(:sections_in_course_count).and_return(3) }
          @assignable = InstructorAssignablesPresenter::Assignable.new(@activity, assignments)
        end

        it 'returns true' do
          expect(@assignable.assignments_vary_by_section?).to be_truthy
        end
      end

      context 'when a section has a category that differs' do
        before do
          assignments = [
            double(Assignment, :due_date => 'foo', :category => 'bar'),
            double(Assignment, :due_date => 'foo', :category => 'baz'),
            double(Assignment, :due_date => 'foo', :category => 'bar')
          ]
          assignments.each {|assignment| allow(assignment).to receive(:sections_in_course_count).and_return(3) }
          @assignable = InstructorAssignablesPresenter::Assignable.new(@activity, assignments)
        end

        it 'returns true' do
          expect(@assignable.assignments_vary_by_section?).to be_truthy
        end
      end

      context 'when the due dates, track_group and categories are the same' do
        before do
          assignments = [
            double(Assignment, :due_date => 'foo', :category => 'bar', :track_group_name => nil ),
            double(Assignment, :due_date => 'foo', :category => 'bar', :track_group_name => nil ),
            double(Assignment, :due_date => 'foo', :category => 'bar', :track_group_name => nil )
          ]
          assignments.each {|assignment| allow(assignment).to receive(:sections_in_course_count).and_return(3) }
          @assignable = InstructorAssignablesPresenter::Assignable.new(@activity, assignments)
        end

        it 'returns false' do
          expect(@assignable.assignments_vary_by_section?).to be_falsey
        end
      end
    end
  end
end
