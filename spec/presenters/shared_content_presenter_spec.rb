describe SharedContentPresenter do
  let(:school) { create(:school) }
  let(:other_school) { create(:school) }
  let(:program) { create(:program) }
  let(:section) { create(:section) }
  let(:course) do
    create(:course,
           sections: [section],
           program:,
           school:)
  end

  let(:strand) { create(:toc_entry) }
  let(:unit) { create(:unit, program:) }
  let(:lesson) { create(:lesson, toc_entries: [strand], unit:) }
  let(:concept) do
    create(:concept,
           lesson:,
           id: strand.location,
           program:)
  end
  let(:instructor) { create(:instructor) }
  let!(:school_user) do
    create(:school_user,
           school:,
           user: instructor)
  end
  let(:igc_activity) do
    create(:instructor_created_activity,
           concept:,
           toc_location: strand.location,
           title: 'Test activity No 1',
           instructor_revision_id: 1,
           lesson:)
  end
  let(:other_igc_activity) do
    create(:instructor_created_activity,
           concept:,
           toc_location: strand.location,
           title: 'Test activity No 2',
           instructor_revision_id: 2,
           lesson:)
  end
  let(:activity_copy) do
    create(:instructor_created_activity,
           concept:,
           toc_location: strand.location,
           title: 'Test activity No 1',
           instructor_revision_id: 1,
           lesson:)
  end
  let(:other_activity_copy) do
    create(:instructor_created_activity,
           concept:,
           toc_location: strand.location,
           title: 'Test activity No 2',
           instructor_revision_id: 2,
           lesson:)
  end
  let(:shared_library_activity) do
    create(:shared_library_activity,
           activity: activity_copy,
           source_activity: igc_activity,
           school:,
           is_shared: true)
  end
  let(:activity_record) { Activity.find activity_copy.id }

  before do
    allow(Maestro::LicenseGroup).to receive(:all).and_return([])
    shared_library_activity
  end

  describe '#lesson_activities' do
    it 'returns activities that are shared for the lesson and school' do
      focus = Focus.new(instructor, program, program.id.to_s => { 'course_id' => course.id })
      presenter = described_class.new(program, instructor, focus, {}, nil)

      expect(presenter.lesson_activities).to match_array([igc_activity])
    end

    it 'does not return activities that are not shared' do
      non_shared_activity = create(:instructor_created_activity,
                                   concept:,
                                   toc_location: strand.location,
                                   lesson:,
                                   instructor_revision_id: 1)

      create(:shared_library_activity,
             activity: non_shared_activity,
             source_activity: igc_activity,
             is_shared: false,
             school:)

      focus = Focus.new(instructor, program, program.id.to_s => { 'course_id' => course.id })
      presenter = described_class.new(program, instructor, focus, {}, nil)

      expect(presenter.lesson_activities).not_to include(non_shared_activity)
    end

    it 'does not return activities created by the current_user' do
      create(:instructor_created_activity,
             concept:,
             toc_location: strand.location,
             title: 'Activity by current user',
             instructor_revision_id: 2,
             lesson:,
             instructor:)

      focus = Focus.new(instructor, program, program.id.to_s => { 'course_id' => course.id })
      presenter = described_class.new(program, instructor, focus, {}, nil)

      activities = presenter.lesson_activities

      expect(activities.map(&:instructor_id)).not_to include(instructor.id)
    end

    it 'returns activities from the first instructor school when course does not exist' do
      focus = Focus.new(instructor, program, {})
      presenter = described_class.new(program, instructor, focus, {}, nil)

      allow(instructor).to receive(:schools).and_return([other_school])

      create(:shared_library_activity,
             activity: other_activity_copy,
             source_activity: other_igc_activity,
             is_shared: true,
             school: other_school)

      expect(presenter.lesson_activities).to include(other_igc_activity)
      expect(presenter.lesson_activities).not_to include(activity_copy)
    end

    it 'returns activities from the school of the course' do
      focus = Focus.new(instructor, program, program.id.to_s => { 'course_id' => course.id })
      presenter = described_class.new(program, instructor, focus, {}, nil)

      expect(presenter.lesson_activities).to include(igc_activity)
    end

    it 'filters activities by shared activity creators' do
      other_instructor = create(:instructor, first_name: 'Creator', last_name: 'One')

      shared_activity = create(:instructor_created_activity,
                               concept:,
                               toc_location: strand.location,
                               instructor: other_instructor,
                               lesson:,
                               instructor_revision_id: 1)

      create(:shared_library_activity,
             activity: shared_activity,
             source_activity: shared_activity,
             is_shared: true,
             school:)

      filters = { shared_activity_creator_ids: [other_instructor.id] }

      focus = Focus.new(instructor, program, program.id.to_s => { 'course_id' => course.id })
      presenter = described_class.new(program, instructor, focus, {}, nil)

      expect(presenter.lesson_activities(filters)).to match_array([shared_activity])
    end

    it 'does not return activities when shared activity creators do not match' do
      other_instructor = create(:instructor, first_name: 'Creator', last_name: 'Two')

      shared_activity = create(:instructor_created_activity,
                               concept:,
                               toc_location: strand.location,
                               instructor: other_instructor,
                               lesson:,
                               instructor_revision_id: 1)

      create(:shared_library_activity,
             activity: shared_activity,
             source_activity: shared_activity,
             is_shared: true,
             school:)

      filters = { shared_activity_creator_ids: [other_instructor.id] }

      focus = Focus.new(instructor, program, program.id.to_s => { 'course_id' => course.id })
      presenter = described_class.new(program, other_instructor, focus, {}, nil)

      expect(presenter.lesson_activities(filters)).to be_empty
    end

    it 'does not return activities that are hidden from my content' do
      hidden_activity = create(:instructor_created_activity,
                               concept:,
                               toc_location: strand.location,
                               title: 'Hidden Activity',
                               instructor_revision_id: 1,
                               lesson:,
                               hide_from_my_content: true)

      create(:shared_library_activity,
             activity: hidden_activity,
             source_activity: hidden_activity,
             is_shared: true,
             school:)

      focus = Focus.new(instructor, program, program.id.to_s => { 'course_id' => course.id })
      presenter = described_class.new(program, instructor, focus, {}, nil)

      expect(presenter.lesson_activities).not_to include(hidden_activity)
    end
  end
end
