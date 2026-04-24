describe PhantomActivityFixer do
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
      toc_location: strand.location
    )
  end
  let(:activity_to_archive) do
    create(
      :activity,
      cms_activity_id: winner_activity.cms_activity_id,
      concept: concept,
      lesson: lesson,
      toc_location: strand.location
    )
  end

  # this assignment is used to test that it has been moved
  # after processing.
  # This is the only assignment in section_two
  let!(:assignment_activity_to_archive) do
    create(
      :assignment,
      section: section_two,
      assignable: activity_to_archive,
      assignable_type: 'Activity',
      due_date: 1.day.ago
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
    described_class.new(winner_activity.id, activity_to_archive.id)
  end

  before do
    # the winner_activity should have more assignments otherwise these tests
    # will fail. Add a couple in random sections.
    create(:assignment, assignable: winner_activity, assignable_type: 'Activity')
    create(:assignment, assignable: winner_activity, assignable_type: 'Activity')

    # both test activities are assigned in section_one
    create(
      :assignment,
      section: section_one,
      assignable: winner_activity,
      assignable_type: 'Activity',
      due_date: 1.day.ago
    )
    create(
      :assignment,
      section: section_one,
      assignable: activity_to_archive,
      assignable_type: 'Activity',
      due_date: 1.day.ago
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

    it 'the array errors should not be empty if the activities do not exist' do
      winner_activity_id = -99
      activity_to_archive_id = -99
      phantom_activity = described_class.new(winner_activity_id, activity_to_archive_id)
      phantom_activity.process
      expect(phantom_activity.errors).not_to be_empty
    end

    it 'the array errors should not be empty if the activities do not match' do
      activity_to_archive.update!(cms_activity_id: activity_to_archive.cms_activity_id - 1)
      phantom_activity = described_class.new(winner_activity.id, activity_to_archive.id)
      phantom_activity.process

      expect(phantom_activity.errors)
        .to eq ["Activities are not phantoms: cms_activity_id does not match"]
    end

    it 'defines a winner activity, the one with most assignments is the winner' do
      phantom_activity.process
      expect(phantom_activity.winner_activity).to eq(winner_activity.id)
      expect(phantom_activity.activity_to_archive).to eq(activity_to_archive.id)
    end

    context 'when the activity does not have a duplicate' do
      let(:id_first_activity) { activity_to_archive.id }
      let(:id_second_activity) { -99 }

      before do
        allow(Activity).to receive(:find)
                       .with(id_first_activity)
                       .and_return(activity_to_archive)
      end

      context ' and there are no assignments' do
        it 'removes the activity from the ToC' do
          allow(activity_to_archive).to receive(:assignments).and_return([])
          phantom_activity = described_class.new(id_first_activity, id_second_activity)
          phantom_activity.process
          activity_to_archive.reload

          expect(activity_to_archive.toc_location).to eq(nil)
          expect(activity_to_archive.toc_location_rank).to eq(nil)
        end
      end

      context ' and there are assignments' do
        it 'does not remove the activity' do
          phantom_activity = described_class.new(id_first_activity, id_second_activity)
          phantom_activity.process
          activity_to_archive.reload

          expect(phantom_activity.errors)
            .to eq ["Activity ##{activity_to_archive.id} has been assigned and cannot be removed."]
          expect(activity_to_archive.toc_location).to_not eq(nil)
          expect(activity_to_archive.toc_location_rank).to_not eq(nil)
        end
      end

      it 'removes the activity if the assignments are in a closed course' do
        section_one.course.update!(end_date: 1.day.ago, allow_past_end_date: true)
        section_two.course.update!(end_date: 1.day.ago, allow_past_end_date: true)
        expect(section_one.assignments.count).to eq 2
        expect(section_two.assignments.count).to eq 1

        phantom_activity = described_class.new(id_first_activity, id_second_activity)
        phantom_activity.process
        activity_to_archive.reload

        expect(activity_to_archive.toc_location).to eq(nil)
        expect(activity_to_archive.toc_location_rank).to eq(nil)
      end

      it 'removes the activity if the assignment sections are archived' do
        section_one.archive
        section_two.archive

        phantom_activity = described_class.new(id_first_activity, id_second_activity)
        phantom_activity.process
        activity_to_archive.reload

        expect(activity_to_archive.toc_location).to eq(nil)
        expect(activity_to_archive.toc_location_rank).to eq(nil)
      end
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
        assignment_activity_to_archive.reload
        expect(assignment_activity_to_archive.assignable_id).to eq(winner_activity.id)
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
