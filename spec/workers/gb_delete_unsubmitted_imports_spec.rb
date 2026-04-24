describe GbDeleteUnsubmittedImportsWorker, new_gb_sync: true do
  let(:section_id) { create(:section).id }
  let(:user_id) { create(:user).id }
  let(:strand) { create(:toc_entry) }
  let(:lesson) { create(:lesson, toc_entries: [strand]) }
  let(:concept) { create(:concept, id: strand.location, lesson: lesson) }
  let(:activity_id) { create(:activity, concept: concept, lesson: lesson).id }

  context 'where there are bad imports' do
    before do
      GradebookEngine::ScoreAction.create(
        section_id: section_id,
        user_id: user_id,
        activity_id: activity_id,
        action: { 'type' => 'import' },
        summation: {}
      )
    end

    it 'deletes a bad import if it is the only record for the section/user/activity' do
      described_class.perform_async(section_id)
      expect(
        GradebookEngine::ScoreAction.where(
          section_id: section_id,
          user_id: user_id,
          activity_id: activity_id
        ).count
      ).to eq(0)
    end

    it 'does not delete a bad import if it is not the most recent record for the section/user/activity' do
      GradebookEngine::ScoreAction.create(
        section_id: section_id,
        user_id: user_id,
        activity_id: activity_id,
        action: { 'type' => 'submit' },
        summation: {}
      )
      described_class.perform_async(section_id)
      expect(
        GradebookEngine::ScoreAction.where(
          section_id: section_id,
          user_id: user_id,
          activity_id: activity_id
        ).count
      ).to eq(2)
    end
  end

  it 'does not delete an import for a score submitted at import time' do
    GradebookEngine::ScoreAction.create(
      section_id: section_id,
      user_id: user_id,
      activity_id: activity_id,
      action: { 'type' => 'import' },
      summation: { 'submitted_at' => '2018-01-19 12:00:00' }
    )
    described_class.perform_async(section_id)
    expect(
      GradebookEngine::ScoreAction.where(
        section_id: section_id,
        user_id: user_id,
        activity_id: activity_id
      ).count
    ).to eq(1)
  end
end
