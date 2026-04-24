describe InstructorContentPresenter do
  include Rails.application.routes.url_helpers
  include RspecJsContentHelpers

  let(:program) { build_stubbed(:program, :id => 49) }
  let(:sections) { [build_stubbed(:section)] }
  let(:course) { build_stubbed(:course) }
  let(:focus) { double('Focus', :sections => sections, :course => course) }
  let(:instructor) { create(:instructor) }

  describe '.new' do
    it 'should init current_user' do
      expect(
        described_class.new('program', instructor, nil, {}, {}).current_user
      ).to eq(instructor)
    end

    it 'should init program' do
      expect(
        described_class.new('program', instructor, nil, {}, {}).program
      ).to eq('program')
    end

    it 'should init sections' do
      expect(
        described_class.new('program', instructor, focus, {}, {}).sections
      ).to eq(sections)
    end

    it 'should raise error when valid params are not passed' do
      expect do
        described_class.new(nil, instructor, 'dontcare', {}, 'dontcare')
      end.to raise_error "not all parameters are valid"
      expect do
        described_class.new('program', nil, 'dontcare', {}, 'dontcare')
      end.to raise_error "not all parameters are valid"
      expect do
        described_class.new('program', 'user', 'dontcare', nil, 'dontcare')
      end.to raise_error "not all parameters are valid"
    end
  end

  describe "#base_url" do
    let(:section) { build_stubbed(:section) }
    let(:program) { build_stubbed(:program) }

    it "should return section toc url" do
      presenter = described_class.new(program, instructor, section, {}, nil)
      expect(presenter.base_url).to eql(instructor_mycontent_path(program))
    end

    it "should append option to the url" do
      presenter = described_class.new(program, instructor, section, {}, nil)
      options = { :all_units => true, :activity_library => 'course' }
      expect(presenter.base_url(options)).to eql(instructor_mycontent_path(program, options))
    end
  end

  describe "#base_url_params" do
    it "should return hash with param" do
      @program = build_stubbed(:program)
      presenter = described_class.new(@program, instructor, nil, {}, nil)
      expect(presenter.base_url_params).to eql({:program_id => @program.id})
    end
  end

  describe "#lesson_activities" do
    let(:program) { create(:program) }
    let(:unit) { create(:unit, program:) }
    let(:section) { create(:section) }
    let(:valid_lesson) { create(:lesson, unit:) }
    let(:instructor_created_activity) do
      create(
        :instructor_created_activity,
        lesson: valid_lesson,
        hide_from_my_content: false,
        instructor_id: instructor.id
      )
    end

    let(:igc_activities) do
      build_list(
        :instructor_created_activity,
        15,
        lesson: valid_lesson,
        hide_from_my_content: false,
        instructor_id: instructor.id
      ) do |activity, index|
        activity.created_at = Time.now - index.days
        activity.updated_at = Time.now - (14 - index).days
        activity.save!
      end
    end
    let(:presenter) { described_class.new(program, instructor, nil, {}, nil) }

    before do
      allow_any_instance_of(InstructorCreatedActivity).to receive(:set_concept)
      allow(Maestro::LicenseGroup).to receive(:all).and_return([double(id: 1, name: 'Test License Group')])
    end

    it "return only created activities that are visible" do
      expect(presenter.lesson_activities).to match_array([instructor_created_activity])

      instructor_created_activity.update!(hide_from_my_content: true)
      expect(presenter.lesson_activities).to match_array([])
    end

    it "does not return activities for other lesson" do
      other_lesson = create(:lesson)
      instructor_created_activity.update!(lesson_id: other_lesson.id)
      instructor_created_activity.reload

      expect(presenter.lesson_activities).to eq([])
    end

    it 'does not return activities created by other instructors' do
      other_instructor = create(:instructor)
      create(
        :instructor_created_activity,
        lesson: valid_lesson,
        hide_from_my_content: false,
        instructor_id: other_instructor.id
      )
      expect(presenter.lesson_activities).to eq([])
    end

    context 'when sorting activities' do
      subject(:presenter) { described_class.new(program, instructor, section, req_params, nil) }

      let(:req_params) { {} }

      before do
        allow(presenter).to receive(:display_lesson).and_return(valid_lesson)
        igc_activities
      end

      context 'when no sorting parameters' do
        it 'sorts the activities by created_at in descending order by default' do
          sorted_activities = InstructorCreatedActivity.order(created_at: :desc).all

          expect(presenter.lesson_activities).to eq(sorted_activities.first(10))
        end
      end

      context 'when invalid sorting parameters' do
        let(:req_params) { { sort_column: 'invalid', sort_direction: 'invalid' } }

        it 'sorts the activities by created_at in descending order by default' do
          sorted_activities = InstructorCreatedActivity.order(created_at: :desc).all

          expect(presenter.lesson_activities).to eq(sorted_activities.first(10))
        end
      end

      context 'when valid sorting parameters' do
        let(:req_params) { { sort_column: 'last_modified', sort_direction: } }

        context 'when sort_direction is desc' do
          let(:sort_direction) { 'desc' }

          it 'sorts the activities by a valid column in descending order' do
            sorted_activities = InstructorCreatedActivity.order(updated_at: :desc).all

            expect(presenter.lesson_activities).to eq(sorted_activities.first(10))
          end
        end

        context 'when sort_direction is asc' do
          let(:sort_direction) { 'asc' }

          it 'sorts the activities by a valid column in ascending order' do
            sorted_activities = InstructorCreatedActivity.order(updated_at: :asc).all

            expect(presenter.lesson_activities).to eq(sorted_activities.first(10))
          end
        end
      end
    end

    context 'with pagination' do
      before do
        # Default records by page is 10
        # Activities count equal to 15 so we'll have total_pages equal to 2

        # Ensures the creation of 15 igc_activities for each test
        igc_activities
      end

      it 'returns by 10 activities' do
        presenter = described_class.new(program, instructor, section, { 'page' => 1 }, nil)
        expect(presenter.lesson_activities.length).to eq(10)
        expect(presenter.lesson_activities).to match_array(igc_activities.first(10))
      end

      it 'returns remaining activities when page is equal to total_pages' do
        presenter = described_class.new(program, instructor, focus, { 'page' => 2 }, nil)
        expect(presenter.lesson_activities.length).to eq(5)
        expect(presenter.lesson_activities).to match_array(igc_activities.last(5))
      end

      it 'does not return any activities when page is more than total_pages' do
        presenter = described_class.new(program, instructor, focus, { 'page' => 4 }, nil)
        expect(presenter.lesson_activities.length).to eq(0)
        expect(presenter.lesson_activities).to match_array([])
      end

      it 'returns first page activities when page parameter is not provided' do
        presenter = described_class.new(program, instructor, focus, {}, nil)
        expect(presenter.lesson_activities.length).to eq(10)
        expect(presenter.lesson_activities).to match_array(igc_activities.first(10))
      end
    end
  end

  describe '#previous_program_edition' do
    let(:current_program) { create(:program, title: 'My program 2.0') }
    let(:previous_program) { create(:program, title: 'My program 1.0') }
    let(:program_edition) do
      create(
        :program_edition,
        program_id: current_program.id,
        previous_edition_program_id: previous_program.id
      )
    end

    context 'when you are in the last edition of the program' do
      before do
        program_edition
      end

      it 'returns the previous edition of the current program' do
        presenter = described_class.new(current_program, instructor, nil, {}, nil)

        expect(presenter.previous_program_edition).to eq(previous_program)
      end
    end

    context 'when you are not in the last edition of the program' do
      before do
        program_edition
      end

      it 'returns nil' do
        presenter = described_class.new(previous_program, instructor, nil, {}, nil)

        expect(presenter.previous_program_edition).to eq(nil)
      end
    end
  end

  describe '#fetch_previous_edition_activities' do
    let(:current_edition) { create(:program, title: 'Current edition') }

    let(:previous_program_edition) { create(:program, title: 'previous edition') }
    let(:unit) { create(:unit, program: previous_program_edition) }
    let(:section) { create(:section) }
    let(:valid_lesson) { create(:lesson, unit:) }

    let(:previous_program_igc_activities) do
      create_list(
        :instructor_created_activity,
        4,
        lesson: valid_lesson,
        hide_from_my_content: false,
        instructor_id: instructor.id
      )
    end

    before do
      allow(Maestro::LicenseGroup).to receive(:all).and_return([double(id: 1, name: 'Test License Group')])
      allow_any_instance_of(InstructorCreatedActivity).to receive(:set_concept)
      previous_program_igc_activities
    end

    context 'when you are in the last edition of the program' do
      it 'returns the igc activities of the previous program edition' do
        presenter = described_class.new(current_edition, instructor, section, {}, nil)

        allow(presenter).to receive(:previous_program_edition).and_return(previous_program_edition)
        expect(presenter.fetch_previous_edition_activities).to eq(previous_program_igc_activities)
      end
    end

    context 'when you are not in the last edition of the program' do
      it 'returns no activities' do
        presenter = described_class.new(current_edition, instructor, section, {}, nil)

        allow(presenter).to receive(:previous_program_edition).and_return(nil)
        expect(presenter.fetch_previous_edition_activities).to eq([])
      end
    end
  end

  describe '#assigned_courses_title' do
    subject(:presenter) { described_class.new(program, instructor, nil, {}, nil) }

    let(:program) { create(:program) }
    let(:course) { create(:course, owner: instructor, name: 'Course 01', program:) }
    let(:section) { create(:section, course:) }
    let(:unit) { create(:unit, program:) }
    let(:lesson) { create(:lesson, unit:) }
    let(:instructor_created_activity) do
      create(
        :instructor_created_activity,
        lesson:,
        hide_from_my_content: false,
        instructor_id: instructor.id
      )
    end

    before do
      allow(Maestro::LicenseGroup).to receive(:all)
        .and_return([double(id: 1, name: 'Test License Group')])
      allow_any_instance_of(InstructorCreatedActivity).to receive(:set_concept)
    end

    context 'when the activity does not have assignments' do
      it 'returns empty' do
        expect(presenter.assigned_courses_title(instructor_created_activity)).to be_empty
      end
    end

    context 'when the activity has assignments' do
      let(:course_2) { create(:course, owner: instructor, name: 'Course 02', program:) }
      let(:section_2) { create(:section, course: course_2) }

      before do
        create(:assignment, assignable: instructor_created_activity, section:)
        create(:assignment, assignable: instructor_created_activity, section: section_2)
      end

      it 'returns the course names' do
        expectd_result = 'Course 01<br>Course 02'
        expect(presenter.assigned_courses_title(instructor_created_activity)).to eq(expectd_result)
      end
    end
  end

  describe '#filter_instructor_activities' do
    let(:program) { create(:program_with_toc_entries) }
    let(:instructor) { create(:instructor) }
    let(:section) { create(:section, program:) }
    let(:presenter) { described_class.new(program, instructor, section, {}, nil) }

    let(:lesson_1) { program.units.first.lessons.first }
    let(:lesson_2) { program.units.last.lessons.first }
    let(:strand_1) { lesson_1.strands.first }
    let(:strand_2) { lesson_2.strands.last }

    let(:activity_1) do
      create(:instructor_created_activity,
             lesson: lesson_1,
             instructor_id: instructor.id,
             hide_from_my_content: false,
             toc_location: strand_1.location,
             activity_type: 'open_ended')
    end

    let(:activity_2) do
      create(:instructor_created_activity,
             lesson: lesson_2,
             instructor_id: instructor.id,
             hide_from_my_content: false,
             toc_location: strand_2.location,
             activity_type: 'composition')
    end

    let(:activities) { InstructorCreatedActivity.all }

    before do
      allow_any_instance_of(InstructorCreatedActivity).to receive(:set_concept)
      allow(Maestro::LicenseGroup).to receive(:all).and_return([double(id: 1, name: 'Test License Group')])

      activity_1
      activity_2
    end

    it 'filters activities by lesson IDs' do
      filtered_activities =
        presenter.filter_instructor_activities([lesson_1.id], nil, nil, nil, activities)
      expect(filtered_activities).to match_array([activity_1])
    end

    it 'filters activities by lesson and strand' do
      filtered_activities =
        presenter.filter_instructor_activities([lesson_1.id],
                                               [strand_1.title],
                                               nil,
                                               nil,
                                               activities)
      expect(filtered_activities).to match_array([activity_1])
    end

    it 'filters activities by activity types' do
      filtered_activities =
        presenter.filter_instructor_activities(nil,
                                               nil,
                                               [activity_2.activity_type],
                                               nil,
                                               activities)
      expect(filtered_activities).to match_array([activity_2])
    end

    it 'filters activities by lesson IDs, strands, and activity types' do
      filtered_activities =
        presenter.filter_instructor_activities([lesson_2.id],
                                               [strand_2.title],
                                               [activity_2.activity_type],
                                               nil,
                                               activities)
      expect(filtered_activities).to match_array([activity_2])
    end

    it 'returns all activities when no filters are applied' do
      filtered_activities = presenter.filter_instructor_activities(nil, nil, nil, nil, activities)
      expect(filtered_activities).to match_array([activity_1, activity_2])
    end

    it 'returns no activities when filters do not match any activities' do
      filtered_activities =
        presenter.filter_instructor_activities([lesson_1.id],
                                               [strand_2.title],
                                               ['Type3'],
                                               nil,
                                               activities)
      expect(filtered_activities).to be_empty
    end
  end

  describe '#activities_by_toc_location' do
    let(:section) { build_stubbed(:section) }
    let(:program) { build_stubbed(:program) }

    it "return activities grouped by toc_location" do
      activity = create_activity_with_unit_lesson_concept_strand_and_substrand(program, instructor_revision_id: 70, instructor_id: instructor.id)

      presenter = described_class.new(program, instructor, section, {}, nil)
      allow(presenter).to receive(:lesson_activities).and_return( [ activity ] )
      expect(presenter.activities_by_toc_location).to eq({ activity.toc_location => [ activity ] })
    end
  end

  describe '#activities_by_toc_entry' do
    before do
      section = build_stubbed(:section)
      program = build_stubbed(:program)
      @presenter = described_class.new(program, instructor, section, {}, nil)
      @activity = create_activity_with_unit_lesson_concept_strand_and_substrand(program, instructor_revision_id: 70, instructor_id: instructor.id)
      activities_by_toc_location = { @activity.toc_location => [ @activity ] }
      allow(@presenter).to receive(:activities_by_toc_location).and_return(activities_by_toc_location)
    end

    it 'returns an empty array when passed toc_entry does not match to any activity' do
      toc_entry = TocEntry.new
      toc_entry.location = "1"

      expect(@presenter.activities_by_toc_entry(toc_entry)).to eq([])
    end

    it 'returns an array of activities which belongs to that toc_entry' do
      toc_entry = TocEntry.new
      toc_entry.location = @activity.toc_location

      expect(@presenter.activities_by_toc_entry(toc_entry)).to eq([@activity])
    end
  end

  describe '#remove_activity_link' do
    let(:activity) { create(:activity, activity_type: 'composition', toc_location: 1) }
    let(:course) { create(:course) }
    let(:section) { build_stubbed(:section) }
    let(:presenter) { described_class.new(program, instructor, section, {}, nil) }

    it 'returns a link with a url if activity is not linked to an open course' do
      allow(course).to receive(:open?).and_return(false)
      allow(activity).to receive(:program).and_return(program)
      allow(activity).to receive(:is_owner?).with(instructor).and_return(true)
      allow(CourseLibraryActivity).to receive_message_chain(:where, :map).and_return([course])
      expected_url = "/instructor/#{program.id}/lessons/#{activity.lesson_id}/toc_entries/#{activity.toc_location}/created_activities/#{activity.id}?activity_type=#{activity.activity_type}&amp;instructor_created_activity[hide_from_my_content]=true"
      expect(presenter.remove_activity_link(activity)).to include expected_url
    end

    it 'returns a link without an url if activity is linked to an open course' do
      CourseLibraryActivity.create(activity_id: activity.id, course_id: course.id)
      allow(activity).to receive(:program).and_return(program)
      allow(activity).to receive(:is_owner?).with(instructor).and_return(true)

      remove_activity_link = presenter.remove_activity_link(activity)
      expect(remove_activity_link).to include 'href="javascript://"'
    end

    it 'returns a link with an url if activity is linked to a closed or archived course' do
      closed_course = create(:course, is_archived: true)
      allow(activity).to receive(:program).and_return(program)
      CourseLibraryActivity.create(activity_id: activity.id, course_id: closed_course.id)

      expected_url = "/instructor/#{program.id}/lessons/#{activity.lesson_id}/toc_entries/#{activity.toc_location}/created_activities/#{activity.id}?activity_type=#{activity.activity_type}&amp;instructor_created_activity[hide_from_my_content]=true"
      expect(presenter.remove_activity_link(activity)).to include expected_url
    end
  end

  describe '#strands' do
    before do
      section = build_stubbed(:section)
      program = build_stubbed(:program)
      @presenter = described_class.new(program, instructor, section, {}, nil)
      @strand_1 = TocEntry.new
      @strand_1.background_color = "#999"
      @substrand = TocEntry.new
      @strand_1.children = [@substrand]
      display_lesson = double(:display_lesson, :strands => [@strand_1])
      allow(@presenter).to receive(:display_lesson).and_return(display_lesson)
    end

    it 'return lesson strands if toc_entry is nil' do
      expect(@presenter.strands).to eq([@strand_1])
    end

    it 'return strands from assessment' do
      expect(@presenter.display_lesson).to receive(:strands).with(true)
      @presenter.strands
    end

    it 'return substrands with same parent background if toc_entry is defined' do
      expected_substrand = @substrand
      expected_substrand.background_color = @strand_1.background_color
      expect(@presenter.strands(@strand_1)).to eq([expected_substrand])
    end
  end

  describe '#uncopied_igc?' do
    before do
      @presenter = described_class.new(program, instructor, nil, {}, nil)
    end

    context 'when the instructor has IGC for a program mapped to the current program' do
      before do
        allow(instructor).to receive(:has_igc_for_source_program?).with(program).and_return(true)
      end

      it 'returns false even if there is uncopied IGC in the current program' do
        allow(instructor)
        .to receive(:has_uncopied_igc_for_source_program?)
        .and_return(true)
        expect(@presenter.uncopied_igc?).to be true
      end

      it 'returns false if all IGC has been copied' do
        allow(instructor).to receive(:has_copied_all_igc?).with(destination: program).and_return(true)
        expect(@presenter.uncopied_igc?).to be false
      end
    end

    it 'returns false if the instructor does not have IGC for a mapped program' do
      allow(instructor).to receive(:has_igc_for_source_program?).with(program).and_return(false)
      expect(@presenter.uncopied_igc?).to be false
    end
  end

  describe '#uncopied_igc_count' do
    let(:source_program) { create(:program) }

    before do
      @presenter = described_class.new(program, instructor, nil, {}, nil)
      allow(@presenter).to receive(:igc_source_program).and_return(source_program)
    end

    context 'when the instructor has uncopied IGC' do
      before do
        allow(instructor).to receive(:has_uncopied_igc_for_source_program?)
          .and_return(true)
      end

      it 'raises an error even if the instructor has uncopied IGC' do
        allow(instructor).to receive(:igc_ids_to_copy).and_return((0..9).to_a)
        expect(@presenter.uncopied_igc_count).to eq(10)
      end
    end

    it 'raises an error if there is no uncopied IGC' do
      allow(instructor).to receive(:has_uncopied_igc_for_source_program?)
        .and_return(false)
      expect { @presenter.uncopied_igc_count }.to raise_error(
        'uncopied_igc_count should not be called if there is no uncopied IGC.'
      )
    end
  end

  describe '#igc_source_program' do
    let(:source_program) { create(:program, title: 'source program') }

    before do
      @presenter = described_class.new(program, instructor, nil, {}, nil)
    end

    it 'returns the source program, if any' do
      allow(ProgramToProgramMapping).to receive(:source_program)
        .and_return(source_program)

      expect(@presenter.igc_source_program).to eq(source_program)
    end

    it 'raises an error if there is no source program' do
      expect { @presenter.igc_source_program }
        .to raise_error(
          'igc_source_program_title should be called only if a source program exists.'
        )
    end
  end

  describe '#shared_activity_creator' do
    let(:institution_admin) { create(:instructor) }
    let(:school) { create(:school) }
    let(:program) { create(:program) }
    let(:unit) { create(:unit, program: program) }
    let(:strand) { create(:toc_entry) }
    let(:lesson) { create(:lesson, toc_entries: [strand], unit: unit) }

    let(:igc_activity) do
      create(
        :instructor_created_activity,
        lesson: lesson,
        toc_entry_id: strand.location,
        instructor: institution_admin
      )
    end

    let(:shared_library_activity) do
      create(
        :shared_library_activity,
        source_activity: igc_activity,
        activity: igc_activity,
        school: school,
        institution_admin_approver_id: institution_admin.id
      )
    end

    before do
      create(:concept, lesson: lesson, program: program, id: strand.location)
      allow(Maestro::LicenseGroup).to receive(:all).and_return(
        [instance_double(Maestro::LicenseGroup, id: 1, name: '01-Supersite')]
      )
      @presenter = described_class.new(program, instructor, nil, {}, nil)
    end

    it 'returns the instructor username' do
      shared_library_activity
      expect(@presenter.shared_activity_creator(igc_activity)).to eq(institution_admin.username)
    end

    it 'returns the instructor username when the instructor is archived' do
      User.find(institution_admin.id).update!(archived: true)
      shared_library_activity

      expect(@presenter.shared_activity_creator(igc_activity)).to eq(institution_admin.username)
    end
  end

  describe '#unshow_activities_approved' do
    let(:institution_admin) { create(:instructor) }
    let(:school) { create(:school) }
    let(:program) { create(:program) }
    let(:unit) { create(:unit, program: program) }
    let(:strand) { create(:toc_entry) }
    let(:lesson) { create(:lesson, toc_entries: [strand], unit: unit) }
    let(:igc_activity) do
      create(:instructor_created_activity, lesson: lesson, toc_entry_id: strand.location)
    end
    let(:activity_copy) do
      create(:instructor_created_activity, lesson: lesson, toc_entry_id: strand.location)
    end
    let(:activity) { create(:activity) }
    let(:shared_library_activity) { create(:shared_library_activity,
                                           source_activity: igc_activity,
                                           activity: activity_copy,
                                           school: school,
                                           institution_admin_approver_id: institution_admin.id) }

    before do
      create(:concept, lesson: lesson, program: program, id: strand.location)
      allow(Maestro::LicenseGroup).to receive(:all).and_return(
        [instance_double(Maestro::LicenseGroup, id: 1, name: '01-Supersite')]
      )
      @presenter = InstructorContentPresenter.new(program, institution_admin, nil, {}, nil)
    end

    it 'show activities that they have not been approved by a institution admin' do
      expect(@presenter.unshow_activities_approved('my_content',
                                                   activity_copy.id,
                                                   institution_admin.id)).to be true
    end

    it 'unshow activities that they have been approved by a institution admin' do
      shared_library_activity
      expect(@presenter.unshow_activities_approved('my_content',
                                                   activity_copy.id,
                                                   institution_admin.id)).to be false
    end

    it 'unshow activities that they have been approved by a institution admin' do
      shared_library_activity
      expect(@presenter.unshow_activities_approved('shared_activity',
                                                   activity_copy.id,
                                                   institution_admin.id)).to be false
    end
  end

  describe '#activity_background_color' do
    let(:institution_admin) { create(:instructor) }
    let(:school) { create(:school) }
    let(:program) { create(:program) }
    let(:unit) { create(:unit, program: program) }
    let(:strand) { create(:toc_entry, location: "123", background_color: "#ff0000") }

    let(:lesson) { create(:lesson, toc_entries: [strand], unit: unit) }
    let(:activity) { create(:activity, toc_location: "123", lesson: lesson) }
    let(:lesson_without_toc) { create(:lesson, toc_entries: [], unit: unit) }
    let(:activity_without_toc) { create(:activity, toc_location: "123", lesson: lesson_without_toc) }

    before do
      @presenter = described_class.new(program, instructor, nil, {}, nil)
    end

    it 'uses the default background color if no strand exists' do
      expect(@presenter.activity_background_color(activity_without_toc)).to eq('#dddddd')
    end

    it 'uses the strand background color if a strand exists' do
      expect(@presenter.activity_background_color(activity)).to eq("#ff0000")
    end
  end
end
