describe TocPresenterCommon do
  let(:user) { build_stubbed(:instructor) }
  let(:course) { build_stubbed(:course) }
  let(:section) { build_stubbed(:section, course: course) }

  let(:presenter_klass) do
    Class.new do
      include Rails.application.routes.url_helpers
      # "Common" means shared between Supersite Junior and non-Supersite Junior
      include TocPresenterCommon
      # "Standard" means "not Supersite Junior"
      include StandardTocPresentation
      include StudentTocPresentation

      attr_accessor :program, :section

      def initialize(user, program, section, base_url)
        self.program = program
        self.current_user = user
        self.section = section
        @base_url = base_url
      end

      def base_url(options = {})
        @base_url
      end

      def sections
        [section]
      end

      def current_focus
        options = {
          program.id.to_s => { 'section_id' => section.id }
        }
        @current_focus = Focus.new(current_user, program, options)
      end
    end
  end

  let(:student_presenter_klass) do
    Class.new do
      include Rails.application.routes.url_helpers
      # "Common" means shared between Supersite Junior and non-Supersite Junior
      include TocPresenterCommon
      # "Standard" means "not Supersite Junior"
      include StandardTocPresentation
      include StudentTocPresentation

      attr_accessor :activities, :sections, :user

      def initialize(activities, sections, user)
        self.current_user = user
        self.activities = activities
        self.sections = sections
        self.course = sections.first.course
      end
    end
  end

  let(:instructor_presenter_klass) do
    Class.new do
      include Rails.application.routes.url_helpers
      include InstructorTocPresentation
      # "Common" means shared between Supersite Junior and non-Supersite Junior
      include TocPresenterCommon
      # "Standard" means "not Supersite Junior"
      include StandardTocPresentation

      attr_accessor :activities, :sections, :user

      def initialize(activities, sections, user)
        self.current_user = user
        self.activities = activities
        self.sections = sections
        self.course = sections.first.course
      end
    end
  end

  before do
    @program = build_stubbed(:program)
    @presenter = presenter_klass.new(user, @program, section, 'base url')
    @lesson = build_stubbed(:lesson)
    allow(@presenter).to receive(:req_params).and_return({:start_unit => 'start_unit', :display_lesson => 'display_lesson', :toc_location =>'toc_location' })
    allow(@presenter).to receive(:saved_location).and_return('saved_location')
  end

  describe '#has_note?' do
    let(:activity) { build_stubbed(:activity) }

    it 'is true when given activity has at least one instructor note' do
      instructor_note = build_stubbed(:activity_note, activity: activity)
      allow(user).to receive_message_chain(:activity_notes, :by_activity).and_return([instructor_note])

      presenter = instructor_presenter_klass.new([activity], [section], user)

      expect(presenter.has_note?(activity)).to be_truthy
    end

    it 'is false when given activity does not have any instructor notes' do
      allow(user).to receive_message_chain(:activity_notes, :by_activity).and_return([])

      presenter = instructor_presenter_klass.new([activity], [section], user)

      expect(presenter.has_note?(activity)).to be_falsey
    end
  end

  describe "#activities" do
    let(:lesson) { build_stubbed(:lesson) }
    let(:activity_1) { build_stubbed(:activity) }
    let(:activity_2) { build_stubbed(:activity) }

    before do
      allow(@presenter).to receive(:current_topic).and_return('start_topic')
      allow(@presenter).to receive(:display_lesson).and_return(lesson)
    end

    it "looks up activities" do
      activity_scope = double(ActiveRecord::Relation).as_null_object
      activities_ids = [1, 2, 3]
      allow(Services::TocActivityList).to receive(:all_for_toc_location).and_return(activities_ids)
      expect(Activity).to receive(:where).with(id: activities_ids).and_return(activity_scope)
      @presenter.activities
    end

    it "assigns the lesson object to each activity" do
      allow(Activity).to receive(:activities_for_toc_location).and_return([activity_1, activity_2])
      @presenter.activities.each do |activity|
        expect(activity.lesson).to eq(lesson)
      end
    end

    it 'calls the activity filter with the correct params' do
      user = build_stubbed(:user)
      course = build_stubbed(:course)
      allow(@presenter).to receive(:library_view).and_return('some library')
      @presenter.current_user = user
      @presenter.course = course
      expect(Services::TocActivityList).to receive(:all_for_toc_location).with(
        'start_topic',
        sections: @presenter.sections,
        current_user: user
      ).and_return([])
      @presenter.activities
    end

    describe 'sorting' do
      let(:strand) { create(:toc_entry) }
      let(:lesson) { create(:lesson, toc_entries: [strand]) }
      let(:concept) { create(:concept, id: strand.location.to_i, lesson: lesson) }

      let(:activity_1) do
        create(
          :activity,
          concept: concept,
          lesson: lesson,
          toc_location: strand.location,
          toc_location_rank: 2
        )
      end
      let(:activity_2) do
        create(
          :activity,
          concept: concept,
          lesson: lesson,
          toc_location: strand.location,
          toc_location_rank: 3
        )
      end

      let(:instructor_activity) do
        create(
          :instructor_created_activity,
          concept: concept,
          lesson: lesson,
          toc_location: strand.location,
          toc_location_rank: 4
        )
      end

      before do
        allow(Maestro::LicenseGroup).to receive(:all).and_return(
          [instance_double(Maestro::LicenseGroup, id: 1, name: '01-Supersite')]
        )
        allow(Services::TocActivityList).to receive(:all_for_toc_location).and_return(
          [activity_2.id, activity_1.id, instructor_activity.id]
        )
      end

      it 'returns instructor-created activities first regardless of their rank' do
        expect(@presenter.activities.map(&:id)).to eq(
          [instructor_activity.id, activity_1.id, activity_2.id]
        )
      end

      it 'does not sort instructor-created activities first if they have a rubric' do
        instructor_activity.update!(has_rubric: true)

        expect(@presenter.activities.map(&:id)).to eq(
          [activity_1.id, activity_2.id, instructor_activity.id]
        )
      end
    end
  end

  describe '#has_more_than_one_lesson?' do
    let(:lesson_1) { build_stubbed(:lesson) }
    let(:lesson_2) { build_stubbed(:lesson) }

    it 'is true when unit has more than 1 lesson' do
      unit = build_stubbed(:unit, :lessons => [lesson_1, lesson_2])
      expect(@presenter.has_more_than_one_lesson?(unit)).to be_truthy
    end

    it 'is false when unit only 1 lesson' do
      unit = build_stubbed(:unit, :lessons => [lesson_1])
      expect(@presenter.has_more_than_one_lesson?(unit)).to be_falsey
    end
  end

  describe '#text_for_lesson_link' do
    let(:lesson_1) { build_stubbed(:lesson) }
    let(:unit_with_lesson) { build_stubbed(:unit, :lessons => [lesson_1]) }

    context "when it's a one-tier program" do
      it 'returns lesson name' do
        allow(@program).to receive(:two_tier?).and_return(false)
        expect(@presenter.text_for_lesson_link(unit_with_lesson, lesson_1)).to eq(lesson_1.name)
      end
    end

    context "when it's a two-tier program" do
      before do
        allow(@program).to receive(:two_tier?).and_return(true)
      end

      context 'when unit has more than one lesson' do
        it 'returns lesson name' do
          lesson_2 = build_stubbed(:lesson)
          unit_with_lessons = build_stubbed(:unit, :lessons => [lesson_1, lesson_2])
          expect(@presenter.text_for_lesson_link(unit_with_lessons, lesson_1)).to eq(lesson_1.name)
          expect(@presenter.text_for_lesson_link(unit_with_lessons, lesson_2)).to eq(lesson_2.name)
        end
      end

      context "when unit has only one lesson" do
        context "when unit and lesson names are different" do
          it 'returns unit and lesson name' do
            allow(lesson_1).to receive(:name).and_return('Different lesson name')
            expected_link_text = "#{unit_with_lesson.name} | #{lesson_1.name}"
            expect(@presenter.text_for_lesson_link(unit_with_lesson, lesson_1)).to eq(expected_link_text)
          end
        end

        context "when unit and lesson names are the same" do
          it 'returns unit and lesson name' do
            allow(lesson_1).to receive(:name).and_return(unit_with_lesson.name)
            expect(@presenter.text_for_lesson_link(unit_with_lesson, lesson_1)).to eq(lesson_1.name)
          end
        end
      end
    end
  end

  describe "#display_lesson" do
    before(:each) do
      unit = build_stubbed(:unit, :lessons => [@lesson])
      allow(@program).to receive(:best_start_unit_rank).with('start_unit',[unit])
      allow(@presenter).to receive(:units).and_return([unit])
      allow(@presenter).to receive(:trial_access?).and_return(false)
    end

    it "should populate display lesson based on program, display_lesson param and units" do
      expect(@program).to receive(:best_display_lesson).with('display_lesson', 'start_unit', @presenter.units, false).and_return('best_display_lesson')
      @presenter.display_lesson
    end
  end

  describe "#display_unit" do
    it"should get display unit from display lesson" do
      expect(@lesson).to receive(:unit)
      expect(@presenter).to receive(:display_lesson).and_return(@lesson)
      @presenter.display_unit
    end
  end

  describe "#current_strand" do
    before do
      @toc_entry = double('toc_entry',:location => 'strand')
      unit = build_stubbed(:unit, :lessons => [@lesson])
      allow(@presenter).to receive(:units).and_return([unit])
      allow(@presenter).to receive(:display_lesson).and_return(@lesson)
      allow(@program).to receive(:units).and_return([unit])
    end
    context "when the strand exists in the unit" do
      it "assigns the strand using the toc_location query param" do
        expect(@lesson).to receive(:parallel_toc_location).and_return(@toc_entry)
        @presenter.current_strand
      end
    end
    context "when the strand does not exist in the unit" do
      it"should get current_strand from display lesson" do
        allow(@lesson).to receive(:parallel_toc_location).and_return(nil)
        expect(@lesson).to receive(:most_relevant_strand).with('toc_location','saved_location').and_return(@toc_entry)
        @presenter.current_strand
      end
    end
  end

  describe '#toc_location_for_lesson' do
    let(:another_lesson) { build_stubbed(:lesson) }
    let(:default_toc_location) { '56498321' }

    before do
      allow(another_lesson).to receive(:default_toc_location).and_return(default_toc_location)
      allow(@presenter).to receive(:display_lesson).and_return(@lesson)
    end

    context 'when there is a parallel toc_location in the lesson' do
      it 'returns the parallel location if location has activities' do
        current_lesson_toc_location = 369741
        allow(another_lesson).to receive(:parallel_or_default_location).and_return(current_lesson_toc_location)
        expect(@presenter.toc_location_for_lesson(another_lesson)).to eq(current_lesson_toc_location)
      end

      it 'returns the default location if location has no activities' do
        current_lesson_toc_location = 369741
        allow(another_lesson).to receive(:parallel_toc_location).and_return(current_lesson_toc_location)
        expect(@presenter.toc_location_for_lesson(another_lesson)).to eq(default_toc_location)
      end
    end

    context 'when there is no parallel toc_location in the lesson' do
      it 'returns the default toc_location for the lessson' do
        allow(another_lesson).to receive(:parallel_toc_location).and_return(nil)
        expect(@presenter.toc_location_for_lesson(another_lesson)).to eq(default_toc_location)
      end
    end
  end

  describe "#current_topic" do
    let(:default_toc_location) { '56498321' }
    let(:parallel_toc_location) { '655463213' }
    let(:most_relevant_toc_location) { '15499856' }

    before do
      allow(@lesson).to receive(:default_toc_location).and_return(default_toc_location)
      allow(@presenter).to receive(:display_lesson).and_return(@lesson)
    end

    context "when the toc location exists in the current lesson" do
      before do
        allow(@lesson).to receive(:parallel_toc_location).and_return(parallel_toc_location)
      end

      it "should get current_topic from the query string " do
        expect(@lesson).to receive(:parallel_toc_location)
        expect(@lesson).not_to receive(:most_relevant_topic).with('toc_location', 'start_strand', 'start_topic', 'saved_location')
        @presenter.current_topic
      end

      it 'returns the parallel toc_location if the location has activities' do
        allow(@lesson).to receive(:parallel_toc_location).and_return(parallel_toc_location)
        allow(@lesson).to receive(:number_of_activities_for_location).and_return(1)
        expect(@presenter.current_topic).to eq(parallel_toc_location)
      end

      it 'returns the default toc_location if the location has no activities' do
        expect(@presenter.current_topic).to eq(default_toc_location)
      end
    end

    context "when the toc location does not exist in the current lesson" do
      before do
        allow(@lesson).to receive(:parallel_toc_location).and_return(nil)
        allow(@lesson).to receive(:most_relevant_topic).and_return(most_relevant_toc_location)
      end

      it "sets the current topic from the display lesson" do
        expect(@lesson).to receive(:most_relevant_topic).with('toc_location', nil, nil, 'saved_location')
        @presenter.current_topic
      end

      it 'returns the most relevant toc_location if the location has activities' do
        allow(@lesson).to receive(:parallel_toc_location).and_return(nil)
        allow(@lesson).to receive(:number_of_activities_for_location).and_return(1)
        expect(@presenter.current_topic).to eq(most_relevant_toc_location)
      end

      it 'returns the default toc_location if the location has no activities' do
        expect(@presenter.current_topic).to eq(default_toc_location)
      end
    end
  end

  describe "#activity_list_header" do
    before do
      allow(@presenter).to receive(:current_topic).and_return('start_topic')
      allow(@presenter).to receive(:display_lesson).and_return(@lesson)
    end

    it "gets the current_topic from display lesson" do
      expect(@lesson).to receive(:activity_list_header).with('start_topic')
      expect(@presenter).to receive(:display_lesson).and_return(@lesson)
      @presenter.activity_list_header
    end
  end

  describe '#strand_url' do
    before do
      # define base_url as a singleton method as it is defined in the
      # toc_presenter and not in shared_toc_helper
      def @presenter.base_url(options)
        instructor_toc_path(program, options)
      end
    end

    it "returns a url with proper query params for strand and substrand links" do
      allow(@presenter).to receive(:course_units_link).and_return(:current_state_url_options => { :all_units => true } )
      expected_query_params = {:start_unit => 'start_unit', :display_lesson => 'display_lesson', :toc_location => 'toc_location', :all_units => 'true'}.to_query
      expect(@presenter.strand_url('start_unit', 'display_lesson', 'toc_location')).to include expected_query_params
    end
  end

  describe "#course_units_link" do
    context "when there is no section (or the section is zero for a student)" do
      it "returns an empty hash" do
        expect(@presenter.course_units_link).to eq({})
      end
    end

    context "when the section covers all program units" do
      it "returns an empty hash" do
        allow(@presenter).to receive(:course_covers_all_program_units?).and_return(true)
        expect(@presenter.course_units_link).to eq({})
      end
    end

    context "when all_units query parameter is true" do
      it "returns the options specifying that the current state is showing all lessons, and the link is to hide them" do
        allow(@presenter).to receive(:needs_course_units_link?).and_return(true)
        allow(@presenter).to receive(:req_params).and_return({ :all_units => 'true' })
        course_link = @presenter.course_units_link
        expect(course_link).to include(:show_all_units_url_options => { :all_units => 'false' }, :current_state_url_options => { :all_units => 'true' })
        expect(course_link[:label]).to eql("Only show units for my course")
      end
    end

    context "when all_units query parameter is false" do
      it "returns the options specifying that the current state is showing only lessons in your course, and the link is to show all lessons" do
        allow(@presenter).to receive(:needs_course_units_link?).and_return(true)
        allow(@presenter).to receive(:req_params).and_return({ :all_units => 'false' })
        course_link = @presenter.course_units_link
        expect(course_link[:show_all_units_url_options]).to include(:all_units => 'true')
        expect(course_link[:current_state_url_options]).to include(:all_units => 'false')
        expect(course_link[:label]).to eql("Show all units")
      end
    end
  end

  describe "#units" do
    let(:course) { build_stubbed(:course) }
    let(:unit) { build_stubbed(:unit) }

    before do
      allow(section).to receive(:course) { course }
      allow(section).to receive(:units) { [unit] }
      allow(@presenter).to receive(:sections) { [section] }
      allow(@presenter).to receive(:req_params) { { all_units: 'flag' } }
    end

    context "when the section exists" do
      it "calls units with the all_units params passed " do
        expect(@presenter.sections.first).to receive(:units).with('flag')
        @presenter.units
      end
    end

    context "when the section does not exist" do
      it "returns the browsable units of the program" do
        allow(@presenter).to receive(:sections) { nil }
        expect(@presenter.program).to receive(:browsable_units)
        @presenter.units
      end
    end

    context 'when section zero' do
      it 'returns the browsable units of the program' do
        allow(@presenter).to receive(:sections) { [Section.section_zero] }
        expect(@presenter.program).to receive(:browsable_units)
        @presenter.units
      end
    end

    context 'when program has a current events unit' do
      it 'includes the current events unit' do
        current_events_unit = build_stubbed(:current_events_unit)
        allow(section).to receive(:units) { [current_events_unit, unit] }
        expect(@presenter.units).to include current_events_unit
      end
    end
  end

  describe "#start_unit" do
    it "looks up start_unit from the display unit" do
      expect(@presenter).to receive(:display_unit).and_return(build_stubbed(:unit))
      @presenter.start_unit
    end
  end

  describe "#lesson_classes" do
    it "included the selected class if current unit is the display unit" do
      allow(@presenter).to receive(:display_unit?).and_return(true)
      allow(@presenter).to receive(:display_lesson?).and_return(false)
      expect(@presenter.lesson_classes(nil,nil)).to eql(" selected_unit_title_link")
    end

    it "included the unselected class if current unit is not the display unit" do
      allow(@presenter).to receive(:display_unit?).and_return(false)
      allow(@presenter).to receive(:display_lesson?).and_return(false)
      expect(@presenter.lesson_classes(nil,nil)).to eql(" unselected_unit_title_link")
    end

    it "included the current lesson class if current lesson is not the display lesson" do
      allow(@presenter).to receive(:display_unit?).and_return(false)
      allow(@presenter).to receive(:display_lesson?).and_return(true)
      expect(@presenter.lesson_classes(nil,nil)).to eql(" unselected_unit_title_link current_lesson")
    end
  end

  describe "#current_lesson_label" do
    context "when there are activities" do
      it "returns the lesson label of the first activity" do
        activity = build_stubbed(:activity)
        lesson = build_stubbed(:lesson)
        allow(lesson).to receive(:display_name).and_return("The display name")
        allow(activity).to receive(:lesson).and_return(lesson)
        allow(@presenter).to receive(:activities).and_return([activity])
        expect(@presenter.current_lesson_label).to eql "The display name"
      end
    end

    it "returns empty string if there are no activities" do
      allow(@presenter).to receive(:activities).and_return([])
      expect(@presenter.current_lesson_label).to eql ''
    end
  end

  describe "#display_unit_visible?" do
    before do
      @presenter.current_user = build_stubbed(:user)
    end

    context "with a user with unreleased_unit_viewer role" do
      before do
        allow(@presenter.current_user).to receive(:can_view_unreleased_units?).and_return(true)
      end

      context "with a released unit" do
        before do
          allow(@presenter).to receive(:display_unit).and_return(build_stubbed(:unit, :released => true))
        end

        it "returns true" do
          expect(@presenter).to be_display_unit_viewable
        end
      end

      context "with a non released unit" do
        before do
          allow(@presenter).to receive(:display_unit).and_return(build_stubbed(:unit, :released => false))
        end

        it "returns true" do
          expect(@presenter).to be_display_unit_viewable
        end
      end
    end

    context "with a user without a unreleased_unit_viewer role" do
      before do
        allow(@presenter.current_user).to receive(:can_view_unreleased_units?).and_return(false)
      end

      context "with a released unit" do
        before do
          allow(@presenter).to receive(:display_unit).and_return(build_stubbed(:unit, :released => true))
        end

        it "returns true" do
          expect(@presenter).to be_display_unit_viewable
        end
      end

      context "with a non released unit" do
        before do
          allow(@presenter).to receive(:display_unit).and_return(build_stubbed(:unit, :released => false))
        end

        it "returns false" do
          expect(@presenter).not_to be_display_unit_viewable
        end
      end
    end
  end

  describe '#units_and_lessons_partial' do
    let(:program) { build_stubbed(:program) }

    before do
      allow(@presenter).to receive(:program).and_return(program)
    end

    context 'when the program has 2 lessons' do
      it 'returns the partial name for a 2 lesson carousel' do
        allow(program).to receive(:units).and_return([1, 2])
        expect(@presenter.units_and_lessons_partial).to eql 'partials/two_units_and_lessons'
      end
    end

    context 'when the program lesson count is not 2' do
      it 'returns the partial name for the standard lesson carousel' do
        allow(program).to receive(:units).and_return([1, 2, 3])
        expect(@presenter.units_and_lessons_partial).to eql 'partials/units_and_lessons'
      end
    end
  end

  describe '#activity_in_course_library?' do
    before do
      allow(@presenter).to receive(:current_topic).and_return('start_topic')
      #@presenter.stub(:display_lesson).and_return(lesson)
    end

    it 'returns true if the activity is in the course library' do
      activity = build_stubbed(:activity)
      activities_ids = [activity.id]
      allow(Services::TocActivityList).to receive(:all_for_toc_location).and_return(activities_ids)
      expect(@presenter.activity_in_course_library?(activity)).to eq(true)
    end

    it 'returns false if the activity is not in the course library' do
      activity = build_stubbed(:activity)
      activities_ids = [activity.id + 1]
      allow(Services::TocActivityList).to receive(:all_for_toc_location).and_return({ hidden: activities_ids, visible: [] })
      expect(@presenter.activity_in_course_library?(activity)).to eq(false)
    end
  end

  describe '#due_date_info_for' do
    let(:student) { create(:student) }
    let(:instructor) { build_stubbed(:instructor) }
    let(:section_1) { create(:section) }
    let(:section_2) { create(:section) }
    let(:activity) { create(:activity) }
    let(:activity_2) { create(:activity) }
    let(:activities) { [activity, activity_2] }
    let(:sections) { [section_1, section_2] }
    let!(:assignment) do
      create(
        :assignment,
        assignable: activity,
        due_date: Date.today,
        section: section_1
      )
    end
    let!(:assignment_2) do
      create(
        :assignment,
        assignable: activity_2,
        due_date: Date.today,
        section: section_2
      )
    end

    context 'when user is a student,' do
      it 'instantiates an AssignmentDueDateHandler object for each activity ' \
         'without passing unassigned sections' do
        expect(TocPresenterCommon::AssignmentDueDateHandler).to receive(:new)
          .with([assignment], nil)
        expect(TocPresenterCommon::AssignmentDueDateHandler).to receive(:new)
          .with([assignment_2], nil)

        presenter = student_presenter_klass.new(activities, sections, student)
        presenter.due_date_info_for(activity.id)
      end
    end

    context 'when user is an instructor,' do
      let(:instructor_presenter) { instructor_presenter_klass.new(activities, sections, instructor) }

      it 'instantiates an AssignmentDueDateHandler object for each activity ' \
         'passing unassigned sections' do
        expect(TocPresenterCommon::AssignmentDueDateHandler).to receive(:new)
          .with([assignment], [section_2])
        expect(TocPresenterCommon::AssignmentDueDateHandler).to receive(:new)
          .with([assignment_2], [section_1])
        instructor_presenter.due_date_info_for(activity.id)
      end

      context 'when an activity has been assigned on all sections' do
        it 'instantiates an AssignmentDueDateHandler object for that ' \
           'activity passing an empty section array' do
          activity_assignment_2 = create(
            :assignment,
            assignable: activity,
            due_date: Date.today,
            section: section_2
          )

          expect(TocPresenterCommon::AssignmentDueDateHandler).to receive(:new)
            .with([assignment, activity_assignment_2], [])
          expect(TocPresenterCommon::AssignmentDueDateHandler).to receive(:new)
            .with([assignment_2], [section_1])

          instructor_presenter.due_date_info_for(activity.id)
        end
      end
    end
  end

  describe '#nothing_assigned?' do
    let(:presenter) { @presenter }
    let(:activity_id) { 1 }
    let(:activity) { double(Activity, id: activity_id) }
    let(:activity_due_date_handler) { double(TocPresenterCommon::AssignmentDueDateHandler) }

    before do
      allow(presenter).to receive(:due_date_info_for) { activity_due_date_handler }
    end

    it 'returns true when no activity has assignments' do
      allow(activity_due_date_handler).to receive(:activity_is_assigned?) { false }
      expect(presenter.nothing_assigned?([activity])).to be_truthy
    end

    it 'returns false when at least one activity has assignments' do
      allow(activity_due_date_handler).to receive(:activity_is_assigned?) { true }
      expect(presenter.nothing_assigned?([activity])).to be_falsey
    end
  end
end

describe TocPresenterCommon::AssignmentDueDateHandler do
  let(:assignment) { build_stubbed(:assignment, due_date: Date.today) }
  let(:assignment_2) { build_stubbed(:assignment, due_date: Date.today) }
  let(:section_1) { build_stubbed(:section) }
  let(:section_2) { build_stubbed(:section) }
  let(:sections) { [section_1, section_2] }
  let(:assignments) { [assignment, assignment_2] }

  include DateTimeHelper
  include AssignmentHelper

  describe '#assignment_id' do
    it 'returns the id of the first of the passed assignments' do
      handler = TocPresenterCommon::AssignmentDueDateHandler.new(assignments, nil)
      expect(handler.assignment_id).to eq(assignment.id)
    end
  end

  describe '#activity_id' do
    it 'returns the activity id of the first of the passed assignments' do
      handler = described_class.new(assignments, nil)
      expect(handler.activity_id).to eq(assignment.assignable_id)
    end
  end

  describe '#individually_assigned?' do
    it 'is false if there are no assignments' do
      handler = described_class.new([], nil)

      expect(handler).not_to be_individually_assigned
    end

    context 'with one assignment,' do
      let(:handler) { described_class.new([assignment], nil) }

      it 'is false if the assignment is not individually-assignable' do
        assignment.individually_assignable = false

        expect(handler).not_to be_individually_assigned
      end

      it 'is true if the assignmetn is individually-assignable' do
        assignment.individually_assignable = true

        expect(handler).to be_individually_assigned
      end
    end

    context 'with multiple assignments,' do
      let(:handler) { described_class.new(assignments, nil) }

      it 'is false if no assignment is individually-assignable' do
        assignment.individually_assignable = false
        assignment_2.individually_assignable = false

        expect(handler).not_to be_individually_assigned
      end

      it 'is true if any assignment is individually-assignable' do
        assignment.individually_assignable = true
        assignment_2.individually_assignable = false

        expect(handler).to be_individually_assigned
      end
    end
  end

  describe '#instructor_due_date_info' do
    let(:handler) { described_class.new(assignments, nil) }

    context 'when there is more than one assignment' do
      context 'when assignments have different due dates' do
        it "returns 'varies'" do
          allow(assignment_2).to receive(:due_date).and_return(1.day.ago.to_date)

          expect(handler.instructor_due_date_info).to eq('varies')
        end
      end

      context 'when assignments have the same due date' do
        it "returns 'varies' when there are unassigned sections" do
          handler = described_class.new(assignments, sections)

          expect(handler.instructor_due_date_info).to eq('varies')
        end

        it 'returns "varies" if any assignment has multiple_due_dates' do
          allow(assignment).to receive(:multiple_due_dates?).and_return(true)

          expect(handler.instructor_due_date_info).to eq('varies')
        end

        context 'when there are not unassigned sections' do
          it 'returns the common assignment due date, formatted for instructor ToC' do
            formatted_due_date = '#Formatted {assignment.due_date}'
            allow(handler).to receive(:format_date_time).and_return(formatted_due_date)

            expect(handler.instructor_due_date_info).to eq(formatted_due_date)
          end
        end
      end
    end
  end

  describe '#due_date_info' do
    it 'returns the due_date, formatted for student ToC' do
      handler = TocPresenterCommon::AssignmentDueDateHandler.new(assignments, nil)
      formatted_due_date = "#Formatted {assignment.due_date}"
      allow(handler).to receive(:format_date_time).and_return(formatted_due_date)
      allow(handler).to receive(:format_due_date_if_late).and_return(formatted_due_date)
      expect(handler.due_date_info('some cool attempt status')).to eq(formatted_due_date)
    end
  end

  describe '#activity_is_assigned?' do
    it 'is true when there is one assignment, at least' do
      handler = TocPresenterCommon::AssignmentDueDateHandler.new(assignments, nil)
      expect(handler.activity_is_assigned?).to be_truthy
    end

    it 'is false when there are no assignments' do
      handler = TocPresenterCommon::AssignmentDueDateHandler.new([], nil)
      expect(handler.activity_is_assigned?).to be_falsey
    end
  end

  describe '#due_date_released?' do
    let(:section_with_release_due_date) do
      build_stubbed(:section, days_to_show_assignment_due_date: '10')
    end

    let(:assignment_with_near_due_date) do
      build_stubbed(
        :assignment,
        due_date: Date.today + 5.day,
        section: section_with_release_due_date
      )
    end

    let(:assignments_with_near_due_date) { [assignment_with_near_due_date] }

    let(:assignment_with_far_due_date) do
      build_stubbed(
        :assignment,
        due_date: Date.today + 15.day,
        section: section_with_release_due_date
      )
    end

    let(:assignments_with_far_due_date) { [assignment_with_far_due_date] }

    let(:assignments_with_release_due_date_not_set) { [assignment] }

    let(:activity_assignments_greater_than_1) {
      [
        assignment_with_near_due_date,
        assignment_with_far_due_date,
        assignment
      ]
    }

    # instructor use case.
    context 'when an activity belongs to more than 1 assignments,' do
      it 'it raises an error of invalid use case' do
        error_text = 'Length of activity_assignments should not be greater than 1.'\
                     'Method "due_date_released?" is for student use case only.'

        handler = described_class.new(activity_assignments_greater_than_1, nil)
        expect { handler.due_date_released? }.to raise_error error_text
      end
    end

    # student use cases.
    context 'when section release due date is set,' do
      it 'it returns true when assignment due date is less than the release due date' do
        handler = described_class.new(assignments_with_near_due_date, nil)
        expect(handler.due_date_released?).to be_truthy
      end

      it 'returns false when assignment due date is greater than the ' \
         'release due date' do
        handler = described_class.new(assignments_with_far_due_date, nil)
        expect(handler.due_date_released?).to be_falsey
      end

      it 'returns nil when activities are not assigned' do
        handler = described_class.new([], nil)
        expect(handler.due_date_released?).to be_nil
      end
    end

    context 'when section release due date is not set,' do
      it 'returns true when activities are assigned' do
        handler = described_class.new(assignments_with_release_due_date_not_set, nil)
        expect(handler.due_date_released?).to be_truthy
      end

      it 'returns nil when activities are not assigned' do
        handler = described_class.new([], nil)
        expect(handler.due_date_released?).to be_nil
      end
    end
  end
end
