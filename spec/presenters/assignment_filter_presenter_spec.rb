describe AssignmentFilterPresenter do
  let(:course) { build_stubbed(:course)}
  let(:program) { build_stubbed(:program)}
  let(:sections) { [build_stubbed(:section, :course => course)]}
  let(:focus) { double("Focus")}
  let(:user) { build_stubbed(:user)}

  describe '#lessons' do
    it 'returns lessons from program' do
      lesson = build_stubbed(:lesson_with_unit)
      allow(program).to receive(:visible_lessons).and_return([lesson])
      presenter = AssignmentFilterPresenter.new(program, sections, course, user, focus, 10)
      expect(presenter.lessons).to eq([lesson])
    end
  end

  describe '#components' do
    it 'returns components labels using the component codes class' do
      components = "components"
      component_codes = double('component_codes')
      allow(component_codes).to receive(:labels).and_return(components)
      expect(ComponentCodes).to receive(:new).with(program).and_return(component_codes)

      presenter = AssignmentFilterPresenter.new(program, sections, course, user, focus, 10)
      expect(presenter.components).to eq(components)
    end
  end

  describe '#content_types' do
    it 'returns content types from program' do
      content_types = "content_types"
      allow(program).to receive(:content_types_selection_list).and_return(content_types)
      presenter = AssignmentFilterPresenter.new(program, sections, course, user, focus, 10)
      expect(presenter.content_types).to eq(content_types)
    end
  end

  describe '#activity_types' do
    let(:activity_type_option_list) { double(AssignmentFilterPresenter::ActivityTypeOptionList, :sorted_options => []) }
    let(:lessons) { [ build_stubbed(:lesson) ] }
    let(:presenter)  { AssignmentFilterPresenter.new(program, sections, course, user, focus, 10) }

    before do
      allow(AssignmentFilterPresenter::ActivityTypeOptionList).to receive(:new).and_return(activity_type_option_list)
      allow(program).to receive(:lessons).and_return(lessons)
    end

    it 'instantiates a new ActivityTypeOptionList, passing in program.lessons' do
      expect(AssignmentFilterPresenter::ActivityTypeOptionList).to receive(:new).with(
        lessons,
        user
      ).and_return(activity_type_option_list)
      presenter.activity_types
    end

    it 'returns the sorted_types value of the ActivityTypeOptionList' do
      list = ['some_stuff']
      expect(activity_type_option_list).to receive(:sorted_options).and_return(list)
      expect(presenter.activity_types).to eq(list)
    end
  end

  describe '#previous_sections' do
    it 'returns all previous section for the user in given program' do
      expect(user).to receive(:all_sections_for_program).with(program).and_return(sections)
      allow(focus).to receive(:sections).and_return([])
      presenter = AssignmentFilterPresenter.new(program, sections, course, user, focus, 10)
      expect(presenter.previous_sections).to eq(sections)
    end

    it "returns previous sections excluding sections in focus" do
      expect(user).to receive(:all_sections_for_program).with(program).and_return(sections)
      allow(focus).to receive(:sections).and_return(sections)
      presenter = AssignmentFilterPresenter.new(program, sections, course, user, focus, 10)
      expect(presenter.previous_sections).to be_empty
    end

    context 'with sections that have archived courses' do
      let(:archived_course) { create(:course) }
      let(:section_of_archived_course) { create(:section, course: archived_course) }

      it 'does not return the sections of archive courses' do
        archived_course.update!(is_archived: true)
        section_of_archived_course.reload
        allow(user).to receive(:all_sections_for_program).with(program).and_return(sections + [section_of_archived_course])
        allow(focus).to receive(:sections).and_return([])
        presenter = AssignmentFilterPresenter.new(program, sections, course, user, focus, 10)
        expect(presenter.previous_sections).not_to include section_of_archived_course
      end
    end
  end

  describe '#filter' do
    it 'returns finds are creates assignment filter' do
      filter = build_stubbed(:assignment_filter)
      lesson = build_stubbed(:lesson_with_unit)
      allow(program).to receive(:visible_lessons).and_return([lesson])
      expect(AssignmentFilter).to receive(:find_or_create).with(user, course, [lesson]).and_return(filter)
      presenter = AssignmentFilterPresenter.new(program, sections, course, user, focus, 10)
      expect(presenter.filter).to eq(filter)
    end
  end

  describe '#strands' do
    it 'returns empty array if is lesson not set in the filter ' do
      filter = build_stubbed(:assignment_filter)
      allow(filter).to receive(:lesson).and_return(nil)
      presenter = AssignmentFilterPresenter.new(program, sections, course, user, focus, 10)
      allow(presenter).to receive(:filter).and_return(filter)
      expect(presenter.strands).to be_empty
    end

    it 'returns strands from lesson if is lesson set in the filter' do
      lesson = build_stubbed(:lesson)
      allow(lesson).to receive(:strands).and_return(['strand_1'])

      filter = build_stubbed(:assignment_filter)
      allow(filter).to receive(:lesson).and_return(lesson)

      presenter = AssignmentFilterPresenter.new(program, sections, course, user, focus, 10)
      allow(presenter).to receive(:filter).and_return(filter)
      expect(presenter.strands).to eql(['strand_1'])
    end
  end

  describe '#categories' do
    it 'returns empty array if previous section not set in the filter ' do
      filter = build_stubbed(:assignment_filter)
      allow(filter).to receive(:previous_section).and_return(nil)
      presenter = AssignmentFilterPresenter.new(program, sections, course, user, focus, 10)
      allow(presenter).to receive(:filter).and_return(filter)
      expect(presenter.categories).to be_empty
    end

    it 'returns categories from previous section if previous section set in the filter' do
      section = build_stubbed(:section)
      allow(section).to receive(:categories).and_return(['category_1'])

      filter = build_stubbed(:assignment_filter)
      allow(filter).to receive(:previous_section).and_return(section)

      presenter = AssignmentFilterPresenter.new(program, sections, course, user, focus, 10)
      allow(presenter).to receive(:filter).and_return(filter)
      expect(presenter.categories).to eql(['category_1'])
    end
  end

  describe '#weeks' do
    it 'returns empty array if previous section not set in the filter ' do
      filter = build_stubbed(:assignment_filter)
      allow(filter).to receive(:previous_section).and_return(nil)
      presenter = AssignmentFilterPresenter.new(program, sections, course, user, focus, 10)
      allow(presenter).to receive(:filter).and_return(filter)
      expect(presenter.weeks).to be_empty
    end

    it 'returns categories from previous section if previous section set in the filter' do
      section = build_stubbed(:section)
      allow(section).to receive(:weeks_covered).and_return(['week_1'])

      filter = build_stubbed(:assignment_filter)
      allow(filter).to receive(:previous_section).and_return(section)

      presenter = AssignmentFilterPresenter.new(program, sections, course, user, focus, 10)
      allow(presenter).to receive(:filter).and_return(filter)
      expect(presenter.weeks).to eql(['week_1'])
    end
  end

  describe '#unassigned_activities' do
    it 'returns actvities filter by the assignment filter' do
      filter = build_stubbed(:assignment_filter)
      activity = build_stubbed(:activity)

      activities = [activity]
      activity_scope = double(ActiveRecord::Relation, :order => activities).as_null_object

      expect(Services::TocActivityList).to receive(:all_unassigned_by_program).with(
        program.id,
        sections:,
        current_user: user
      ).and_return([activity.id])
      allow(Activity).to receive(:includes).with(:concept, :lesson).and_return(Activity)
      allow(Activity).to receive(:where).with(id: [activity.id]).and_return(activity_scope)
      allow(activity_scope).to receive(:order).with('activities.lesson_id, activities.toc_location_rank').and_return(activities)
      expect(filter).to receive(:filter).with(activities, 10).and_return(activities)

      presenter = AssignmentFilterPresenter.new(program, sections, course, user, focus, 10)
      allow(presenter).to receive(:filter).and_return(filter)

      expect(presenter.unassigned_activities).to eql(activities)
    end

    it 'uses table-prefixed column names in ORDER BY to avoid MySQL ambiguity' do
      # This test ensures that when using .includes(:concept, :lesson), the ORDER BY clause
      # uses 'activities.lesson_id' instead of just 'lesson_id' to avoid MySQL error:
      # "Column 'lesson_id' in order clause is ambiguous" since both activities and concepts tables have lesson_id
      filter = build_stubbed(:assignment_filter)
      activity = build_stubbed(:activity)

      expect(Services::TocActivityList).to receive(:all_unassigned_by_program).with(
        program.id,
        sections:,
        current_user: user
      ).and_return([activity.id])

      # Verify that the ORDER BY clause uses table prefixes
      expect(Activity).to receive(:includes).with(:concept, :lesson).and_return(Activity)
      expect(Activity).to receive(:where).with(id: [activity.id]).and_return(Activity)
      expect(Activity).to receive(:order).with('activities.lesson_id, activities.toc_location_rank').and_return([activity])

      presenter = AssignmentFilterPresenter.new(program, sections, course, user, focus, 10)
      allow(presenter).to receive(:filter).and_return(filter)
      allow(filter).to receive(:filter).and_return([activity])

      presenter.unassigned_activities
    end
  end

  describe "#activities" do
    it "is an alias method to unassigned_activities (used in instructor assignable activity module)" do
      filter = build_stubbed(:assignment_filter)
      presenter = AssignmentFilterPresenter.new(program, sections, course, user, focus, 10)
      allow(presenter).to receive(:filter).and_return(filter)
      expect(filter).to receive(:filter)
      presenter.activities
    end
  end

  describe '#grouped_unassigned_activities' do
    before do
      unit_1 = build_stubbed(:unit, :rank => 1)

      lesson_1 = build_stubbed(:lesson, :unit => unit_1, :rank => 1)
      lesson_2 = build_stubbed(:lesson, :unit => unit_1, :rank => 2)

      @activity_1 = build_stubbed(:activity, :title => "Activity 1", :lesson => lesson_1)
      allow(@activity_1).to receive(:lesson_name).and_return("Lesson 1")
      allow(@activity_1).to receive(:concept_name).and_return("Strand Name 1")
      allow(@activity_1).to receive(:toc_location_rank_in_lesson).and_return(1)
      allow(@activity_1).to receive(:toc_location_rank).and_return(1)

      @activity_2 = build_stubbed(:activity,  :title => "Activity 2", :lesson => lesson_1)
      allow(@activity_2).to receive(:lesson_name).and_return("Lesson 1")
      allow(@activity_2).to receive(:concept_name).and_return("Strand Name 1")
      allow(@activity_2).to receive(:toc_location_rank_in_lesson).and_return(1)
      allow(@activity_2).to receive(:toc_location_rank).and_return(2)

      @activity_3 = build_stubbed(:activity,  :title => "Activity 3", :lesson => lesson_2)
      allow(@activity_3).to receive(:lesson_name).and_return("Lesson 2")
      allow(@activity_3).to receive(:concept_name).and_return("Strand Name 1")
      allow(@activity_3).to receive(:toc_location_rank_in_lesson).and_return(1)
      allow(@activity_3).to receive(:toc_location_rank).and_return(2)

      @activity_4 = build_stubbed(:activity,  :title => "Activity 4", :lesson => lesson_2)
      allow(@activity_4).to receive(:lesson_name).and_return("Lesson 2")
      allow(@activity_4).to receive(:concept_name).and_return("Strand Name 2")
      allow(@activity_4).to receive(:toc_location_rank_in_lesson).and_return(2)
      allow(@activity_4).to receive(:toc_location_rank).and_return(1)

      @activity_5 = build_stubbed(:activity,  :title => "Activity 5", :lesson => lesson_2)
      allow(@activity_5).to receive(:lesson_name).and_return("Lesson 2")
      allow(@activity_5).to receive(:concept_name).and_return("Strand Name 1")
      allow(@activity_5).to receive(:toc_location_rank_in_lesson).and_return(1)
      allow(@activity_5).to receive(:toc_location_rank).and_return(1)

      @presenter = AssignmentFilterPresenter.new(program, sections, course, user, focus, 10)
      unassigned_activities = [@activity_3, @activity_5, @activity_2, @activity_4, @activity_1]
      allow(@presenter).to receive(:unassigned_activities).and_return(unassigned_activities)
    end

    it 'returns actvities filter by the assignment filter' do
      results = [ ["Lesson 1 | Strand Name 1", [@activity_1,@activity_2]],
                  ["Lesson 2 | Strand Name 1", [@activity_5, @activity_3]],
                  ["Lesson 2 | Strand Name 2", [@activity_4]] ]
      expect(@presenter.grouped_unassigned_activities).to eql(results)

    end
  end

  describe "#lesson_name_class" do
    let(:activities) { [build_stubbed(:activity)] }
    let(:presenter)  { AssignmentFilterPresenter.new(program, sections, course, user, focus, 10) }

    it "returns 'toc_location_component' when there are assignable activities within a component" do
      expect(presenter).to receive(:any_assignable?).with(activities).and_return(true)
      expect(presenter.lesson_name_class(activities)).to eq('')
    end

    it "returns 'toc_location_component unassignable_component' when there are no assignable activities within a component" do
      expect(presenter).to receive(:any_assignable?).with(activities).and_return(false)
      expect(presenter.lesson_name_class(activities)).to eq('unassignable_lesson')
    end
  end
end

describe AssignmentFilterPresenter::ActivityTypeOptionList do
  let(:lesson) { build_stubbed(:lesson) }
  let(:user) { build_stubbed(:user)}
  let(:option_list) { AssignmentFilterPresenter::ActivityTypeOptionList.new(lesson, user) }

  before do
    allow(Activity).to receive(:humanize_activity_type).with('a_type').and_return('A type')
    allow(Activity).to receive(:humanize_activity_type).with('b_type').and_return('B type')
  end

  describe '#sorted_options' do
    it 'returns an empty array when there are no activities in the specified lessons' do
      expect(option_list.sorted_options).to eq([])
    end

    it 'returns an array of options with the activity_type and human-readable activity type' do
      create(:activity, :activity_type => 'a_type', :lesson => lesson)
      create(:activity, :activity_type => 'b_type', :lesson => lesson)
      expect(option_list.sorted_options).to eq([['A type', 'a_type'], ['B type', 'b_type']])
    end

    it 'returns only activities_types from the specified lessons' do
      create(:activity, :activity_type => 'a_type', :lesson => lesson)
      create(:activity, :activity_type => 'b_type', :lesson => build_stubbed(:lesson))
      expect(option_list.sorted_options).to eq([['A type', 'a_type']])
    end

    it 'de-dupes activity types' do
      create(:activity, :activity_type => 'a_type', :lesson => lesson)
      create(:activity, :activity_type => 'a_type', :lesson => lesson)
      expect(option_list.sorted_options).to eq([['A type', 'a_type']])
    end

    it 'filters out nil activity types' do
      create(:activity, :activity_type => 'a_type', :lesson => lesson)
      create(:activity, :activity_type => nil, :lesson => lesson)
      expect(option_list.sorted_options).to eq([['A type', 'a_type']])
    end

    it 'returns options sorted alphabetically by their human-readable activity type' do
      # using aa_type to show that we're not sorting by activity_type
      allow(Activity).to receive(:humanize_activity_type).with('aa_type').and_return('C type')

      create(:activity, :activity_type => 'b_type', :lesson => lesson)
      create(:activity, :activity_type => 'aa_type', :lesson => lesson)
      create(:activity, :activity_type => 'a_type', :lesson => lesson)

      expect(option_list.sorted_options).to eq([['A type', 'a_type'], ['B type', 'b_type'], ['C type', 'aa_type']])
    end

    context 'when multiple activity types have the same human-readable type' do
      it 'returns a comma-separated list of activity_types for the human-readable type', test_debt: true do
        skip 'Fails when running independently'
        allow(Activity).to receive(:humanize_activity_type).with('a_type_variant').and_return('A type')

        create(:activity, :activity_type => 'a_type', :lesson => lesson)
        create(:activity, :activity_type => 'a_type_variant', :lesson => lesson)

        results = option_list.sorted_options
        expect(results.size).to eq(1)
        expect(results.first[0]).to eq('A type')
        # A little extra complexity here because the order of the types could vary
        expect(results.first[1].split(',')).to match_array(['a_type', 'a_type_variant'])
      end
    end
  end

end
