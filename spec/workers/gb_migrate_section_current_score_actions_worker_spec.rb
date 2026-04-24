describe GbMigrateSectionCurrentScoreActionsWorker, new_gb_sync: true do
  let(:section) { create(:gb_section) }
  let(:section_id) { section.id }
  let(:user_id) { create(:user).id }
  let(:strand) { create(:toc_entry) }
  let(:lesson) { create(:lesson, toc_entries: [strand]) }
  let(:concept) { create(:concept, id: strand.location, lesson: lesson) }
  let(:activity_id) { create(:activity, concept: concept, lesson: lesson).id }

  before do
    # Add section to migratable-section table.
    migratable_section = GradebookEngine::MigratableSection.new
    migratable_section.section_id = section_id
    migratable_section.migrated = false
    migratable_section.save
  end

  context 'when there is not a corresponding current_score_actions record' do
    it 'copies the most recent score_actions record to current_score_actions' do
      # Create a score action for the section/user/activity.
      create(
        :gb_score_action,
        action: { type: 'submit' },
        activity_id: activity_id,
        school_id: section.school_id,
        section_id: section_id,
        summation: { foo: 'bar' },
        user_id: user_id
      )

      # Create a second score action for the same section/user/activity.
      score_action_2 = create(
        :gb_score_action,
        action: { type: 'submit' },
        activity_id: activity_id,
        school_id: section.school_id,
        section_id: section_id,
        summation: { baz: 'qux' },
        user_id: user_id
      )

      # Delete the current_score_actions record that was created by the trigger.
      GradebookEngine::CurrentScoreAction.where(
        activity_id: activity_id,
        section_id: section_id,
        user_id: user_id
      ).first.destroy

      # Call the worker.
      described_class.new.perform(section_id)

      # Assert that the expected current_score_actions record now exists.
      current_score_action = GradebookEngine::CurrentScoreAction.where(
        activity_id: activity_id,
        section_id: section_id,
        user_id: user_id
      ).first

      expect(current_score_action.score_action_id).to eq(score_action_2.id)
      expect(current_score_action.summation).to eq(score_action_2.summation)

      # Assert that the section has been marked as migrated.
      expect(
        GradebookEngine::MigratableSection.where(
          section_id: section_id
        ).first.migrated
      ).to be_truthy
    end
  end

  context 'when there is a corresponding current_score_actions record' do
    context 'and the current_score_actions record is less recent than the score_actions record' do
      it 'updates the score_action_id, summation, and updated_at fields' do
        # Create a score action for the section/user/activity.
        score_action_1 = create(
          :gb_score_action,
          action: { type: 'submit' },
          activity_id: activity_id,
          section_id: section_id,
          summation: { foo: 'bar' },
          user_id: user_id
        )

        # Create a second score action for the same section/user/activity.
        score_action_2 = create(
          :gb_score_action,
          action: { type: 'submit' },
          activity_id: activity_id,
          section_id: section_id,
          summation: { baz: 'qux' },
          user_id: user_id
        )
        # The trigger is in place, so there should be a current_score_actions record now;
        #   change its score_action_id to the ID of the first score action,
        #   and set its summation to that of the first score action
        #   so that we can later assert its value has been updated.
        current_score_action = GradebookEngine::CurrentScoreAction.where(
          activity_id: activity_id,
          section_id: section_id,
          user_id: user_id
        ).first

        current_score_action.score_action_id = score_action_1.id
        current_score_action.summation = score_action_1.summation
        current_score_action.save

        # Call the worker.
        described_class.new.perform(section_id)

        # Assert that the current_score_actions record has been updated
        #   with values from the second score action.
        current_score_action = GradebookEngine::CurrentScoreAction.where(
          activity_id: activity_id,
          section_id: section_id,
          user_id: user_id
        ).first

        current_score_action.score_action_id = score_action_1.id
        current_score_action.summation = score_action_1.summation
        current_score_action.save

        # Call the worker.
        described_class.new.perform(section_id)

        # Assert that the current_score_actions record has been updated
        #   with values from the second score action.
        current_score_action = GradebookEngine::CurrentScoreAction.where(
          activity_id: activity_id,
          section_id: section_id,
          user_id: user_id
        ).first

        expect(current_score_action.score_action_id).to eq(score_action_2.id)
        expect(current_score_action.summation).to eq(score_action_2.summation)

        # Assert that the section has been marked as migrated.
        expect(
          GradebookEngine::MigratableSection.where(
            section_id: section_id
          ).first.migrated
        ).to be_truthy
      end
    end

    context 'and the current_score_actions record is the same version as the score_actions record' do
      it 'does nothing' do
        # Create a score action for the section/user/activity.
        score_action_1 = create(
          :gb_score_action,
          action: { type: 'submit' },
          activity_id: activity_id,
          section_id: section_id,
          summation: { foo: 'bar' },
          user_id: user_id
        )

        # The trigger is in place, so there should now be a current_score_actions record
        #   with a score_action_id equal to the ID of the score action.
        # Set its summation to a new value that we can later assert hasn't changed.
        current_score_action = GradebookEngine::CurrentScoreAction.where(
          activity_id: activity_id,
          section_id: section_id,
          user_id: user_id
        ).first
        new_summation = { 'rab' => 'oof' }
        current_score_action.summation = new_summation
        current_score_action.save

        # Call the worker.
        described_class.new.perform(section_id)

        # Assert that the current_score_actions record has not been updated.
        current_score_action = GradebookEngine::CurrentScoreAction.where(
          activity_id: activity_id,
          section_id: section_id,
          user_id: user_id
        ).first

        expect(current_score_action.score_action_id).to eq(score_action_1.id)
        expect(current_score_action.summation).to eq(new_summation)

        # Assert that the section has been marked as migrated.
        expect(
          GradebookEngine::MigratableSection.where(
            section_id: section_id
          ).first.migrated
        ).to be_truthy
      end
    end

    context 'and the current_score_actions record is more recent than the score_actions record' do
      it 'does nothing' do
        # Create a score action for the section/user/activity.
        score_action_1 = create(
          :gb_score_action,
          action: { type: 'submit' },
          activity_id: activity_id,
          section_id: section_id,
          summation: { foo: 'bar' },
          user_id: user_id
        )
        # Create another score action, just to get a valid score action id to
        # use, otherwise changing the current_score_action's
        # score_action_id would raise an error:
        # Validation failed: Score action must exist
        activity_2 = create(:activity, concept: concept, lesson: lesson)
        score_action_2 = create(
          :gb_score_action,
          activity_id: activity_2.id,
          user_id: user_id
        )

        # Delete the CurrentScoreAction that was automatically created to
        # avoid a uniqness constraint error.
        GradebookEngine::CurrentScoreAction.find_by(
          activity_id: activity_2.id
        ).destroy

        # The trigger is in place, so there should be a current_score_actions record now.
        #   Add 1 to its score_action_id.
        #   Also, set its summation to a new value that we can later assert hasn't changed.
        current_score_action = GradebookEngine::CurrentScoreAction.where(
          activity_id: activity_id,
          section_id: section_id,
          user_id: user_id
        ).first
        current_score_action.score_action_id = score_action_2.id
        new_summation = { 'rab' => 'oof' }
        current_score_action.summation = new_summation
        current_score_action.save!

        # Call the worker.
        described_class.new.perform(section_id)

        # Assert that the current_score_actions record has not been updated.
        current_score_action = GradebookEngine::CurrentScoreAction.where(
          activity_id: activity_id,
          section_id: section_id,
          user_id: user_id
        ).first

        expect(current_score_action.score_action_id).to eq(score_action_2.id)
        expect(current_score_action.summation).to eq(new_summation)

        # Assert that the section has been marked as migrated.
        expect(
          GradebookEngine::MigratableSection.where(
            section_id: section_id
          ).first.migrated
        ).to be_truthy
      end
    end
  end
end
