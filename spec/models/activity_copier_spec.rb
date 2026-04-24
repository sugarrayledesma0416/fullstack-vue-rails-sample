describe ActivityCopier do
  include RspecJsContentHelpers

  let(:course) { create(:course, owner: instructor, program: program) }
  let(:program) { create(:program, family: 'vista_online_learning') }
  let(:instructor) { create(:instructor) }
  let(:strand) { create(:toc_entry) }
  let!(:concept) { create(:concept, id: strand.location.to_i, lesson: lesson) }
  let(:lesson) { create(:lesson, toc_entries: [strand]) }
  let(:composition_content_path) do
    File.join('spec', 'fixtures', 'xml', 'composition_with_rubric.xml')
  end

  let!(:activity) do
    create_activity_with_content(
      composition_content_path,
      program,
      {
        lesson: lesson,
        strand_id: strand.location,
        title: 'original title',
        icon: 'textbook,composition'
      }
    )
  end

  let(:copier) { described_class.new(activity.id, instructor.id, course.id) }
  let(:result) { InstructorCreatedActivity.last }

  before do
    allow(Maestro::LicenseGroup).to receive(:all).and_return(
      [instance_double(Maestro::LicenseGroup, id: 1, name: '01-Supersite')]
    )
  end

  describe '#copy' do
    before do
      # Override the stubs from create_activity_with_content
      # to be able to write the new xml.
      allow(Activity).to receive(:filepath_from_revision_id).with(
        anything, true, false
      ).and_call_original
    end

    it 'creates an InstructorCreatedActivity with attributes of the specified ' \
       'activity' do
      copier.copy

      @recycle_bin << result.content_filepath if result

      expect(result).to have_attributes(
        activity_type: 'composition',
        component_name: activity.component_name,
        concept_rank: activity.concept_rank,
        concept_id: concept.id,
        has_rubric: true,
        instructor_id: instructor.id,
        lesson_id: lesson.id,
        minutes_to_complete: activity.minutes_to_complete,
        title: activity.title,
        toc_location: strand.location.to_i,
        toc_location_rank: activity.toc_location_rank
      )
    end

    it 'creates a custom_rubric record when the activity has a rubric' do
      copier.copy

      @recycle_bin << result.content_filepath if result

      expect(result.custom_rubric).to have_attributes(
        course_id: course.id,
        draft: true,
        instructor_id: instructor.id,
        source_activity_id: activity.id,
        source_rubric_id: 1,
        strand_id: strand.location.to_i
      )
    end

    it 'does not create more than one copy when the activity has a rubric' do
      copier.copy
      copier.copy

      @recycle_bin << result.content_filepath if result

      expect(InstructorCreatedActivity.count).to eq(1)
      expect(copier.errors).to contain_exactly(
        'You may not make more than one copy'
      )
    end

    it 'copies the icon information correctly' do
      copier.copy

      @recycle_bin << result.content_filepath if result

      expect(result.icon).to eq('textbook,composition')
    end
  end

  describe '#valid?' do
    before do
      # Override the stubs from create_activity_with_content
      # to be able to write the new xml.
      allow(Activity).to receive(:filepath_from_revision_id).with(
        anything, true, false
      ).and_call_original
    end

    context 'when the specified activity exists' do
      it 'is true' do
        copier.copy

        expect(copier).to be_valid
      end
    end

    context 'when the specified activity does not exist' do
      let(:copier) do
        described_class.new(activity.id + 1, instructor.id, course.id)
      end

      before do
        copier.copy
      end

      it 'is false' do
        expect(copier).not_to be_valid
      end

      it 'populates an error that the activity does not exist' do
        expect(copier.errors).to contain_exactly(
          'Activity not found'
        )
      end
    end
  end
end
