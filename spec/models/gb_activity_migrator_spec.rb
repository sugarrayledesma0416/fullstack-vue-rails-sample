describe GbActivityMigrator do
  let(:m3_activity) { create(:activity, title: 'Test Activity 1') }
  let(:add_update_params) do
    { model_name: 'Activity', id: m3_activity.id, action: 'add_update' }
  end

  before do
    create(:gb_strand, id: m3_activity.concept_id)
    create(:gb_lesson, id: m3_activity.lesson_id)
  end

  describe 'add_update model action' do
    it 'creates a new gradebook activity record if it does not exist' do
      gb_migrator = described_class.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy
      new_gb_activity = ::GradebookEngine::Activity.find(m3_activity.id)
      expect(new_gb_activity.name).to eql(m3_activity.title)
      expect(new_gb_activity.rank).to eq(m3_activity.concept_rank)
    end

    it 'updates existing gradebook activity record' do
      gb_activity = ::GradebookEngine::Activity.new(
        id: m3_activity.id,
        lesson_id: m3_activity.lesson_id,
        strand_id: m3_activity.concept_id,
        name: 'Existing M3 Activity',
        rank: m3_activity.concept_rank
      )
      gb_activity.save!
      gb_activity = ::GradebookEngine::Activity.find(m3_activity.id)
      expect(gb_activity.name).to eql('Existing M3 Activity')
      m3_activity.title = 'Modified M3 Activity'
      m3_activity.concept_rank = m3_activity.concept_rank + 1
      m3_activity.save!
      gb_migrator = described_class.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy
      updated_gb_activity = ::GradebookEngine::Activity.find(m3_activity.id)
      expect(updated_gb_activity.name).to eql('Modified M3 Activity')
      expect(updated_gb_activity.rank).to eq(m3_activity.concept_rank)
    end
  end

  describe 'delete model action' do
    it 'deletes an existing gradebook Activity record' do
      gb_activity = ::GradebookEngine::Activity.new(
        id: m3_activity.id,
        lesson_id: m3_activity.lesson_id,
        strand_id: m3_activity.concept_id,
        name: 'Existing M3 Activity',
      )
      gb_activity.save!
      gb_activity = ::GradebookEngine::Activity.find(m3_activity.id)
      expect(gb_activity.name).to eql('Existing M3 Activity')
      gb_migrator = described_class.new(m3_activity.gb_deletion_opts)
      result = gb_migrator.update_object
      expect(result).to be_nil
      expect{ ::GradebookEngine::Activity.find(m3_activity.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
