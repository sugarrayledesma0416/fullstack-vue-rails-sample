describe PhantomActivityMigrator do
  # this test coverage supplements coverage provided by the base
  # class specs and are meant only to cover the special case
  # defined by this class
  let(:strand) { create(:toc_entry) }
  let(:program) { create(:program) }
  let(:unit) { create(:unit, program: program) }
  let(:lesson) { create(:lesson, toc_entries: [strand], unit: unit) }
  let(:student) { create(:student) }
  let(:section_one) { create(:section) }
  let(:section_two) { create(:section) }
  let(:concept) do
    create(:concept, lesson: lesson, program: program, id: strand.location)
  end
  let(:winner_activity) do
    create(
      :activity,
      concept: concept,
      lesson: lesson,
      toc_location: strand.location,
      title: 'title'
    )
  end
  let(:activity_to_archive) do
    create(
      :activity,
      concept: concept,
      lesson: lesson,
      toc_location: strand.location,
      title: 'title'
    )
  end

  let!(:assignment_archived_activity_two) do
    create(
      :assignment,
      section: section_two,
      assignable: activity_to_archive,
      assignable_type: 'Activity'
    )
  end
  let!(:attempt_two) do
    create(
      :attempt,
      user_id: student.id,
      activity: activity_to_archive,
      section: section_two,
      status_code: AttemptStatus::CODE_COMPLETED
    )
  end
  let(:phantom_activity) do
    described_class.new(activity_to_archive.id, winner_activity.id)
  end

  before do
    create(:assignment, assignable: winner_activity, assignable_type: 'Activity')
    create(:assignment, assignable: winner_activity, assignable_type: 'Activity')
    create(
      :assignment,
      section: section_one,
      assignable: winner_activity,
      assignable_type: 'Activity'
    )
    create(
      :assignment,
      section: section_one,
      assignable: activity_to_archive,
      assignable_type: 'Activity'
    )
    create(
      :attempt,
      activity: winner_activity,
      section: section_one,
      status_code: AttemptStatus::CODE_COMPLETED
    )
    section_one.students << Attempt.last.user
  end

  describe '#process' do
    it 'the array errors should be empty if the activities exists' do
      phantom_activity.process
      expect(phantom_activity.errors).to be_empty
    end

    it 'the array errors should not be empty if the activities do not exists' do
      winner_activity_id = -99
      activity_to_archive_id = -99
      phantom_activity = described_class.new(winner_activity_id, activity_to_archive_id)
      phantom_activity.process
      expect(phantom_activity.errors).not_to be_empty
    end

    context 'when the activity has been assigned and has a duplicate' do
      it 'selects a winner activity' do
        section_two.students << student
        phantom_activity.process
        attempt_two.reload
        expect(attempt_two.activity_id).to eq(winner_activity.id)
      end

      it 'updates the attempt duration with the winner activity', new_gb_sync: true do
        section_two.students << student
        attempt_duration = GradebookEngine::AttemptDuration.create!(
          activity_id: activity_to_archive.id,
          section_id: section_two.id,
          user_id: student.id
        )
        phantom_activity.process
        attempt_duration.reload
        expect(attempt_duration.activity_id).to eq(winner_activity.id)
      end

      it 'creates the score actions with the winner activity', new_gb_sync: true do
        section_two.students << student
        GradebookEngine::ScoreAction.create!(
          action: { 'type' => 'drop_score' },
          activity_id: activity_to_archive.id,
          section_id: section_two.id,
          user_id: student.id
        )
        expect do
          phantom_activity.process
        end.to change(GradebookEngine::ScoreAction, :count).by(1)
      end

      it 'updates the assignments with the winner activity' do
        phantom_activity.process
        assignment_archived_activity_two.reload
        expect(assignment_archived_activity_two.assignable_id).to eq(winner_activity.id)
      end

      it 'deletes the assignment of the activity to archive' do
        phantom_activity.process
        phantom_activity.section_ids_to_move.each do |section_id|
          assignment = Assignment.where(assignable_id: activity_to_archive.id,
                                        assignable: 'Activity',
                                        section_id: section_id).to_a
          expect(assignment).to eq([])
        end
      end

      it 'removes the activity to archive from the ToC' do
        phantom_activity.process
        activity_to_archive.reload
        expect(activity_to_archive.toc_location).to eq(nil)
        expect(activity_to_archive.toc_location_rank).to eq(nil)
      end
    end
  end
end
