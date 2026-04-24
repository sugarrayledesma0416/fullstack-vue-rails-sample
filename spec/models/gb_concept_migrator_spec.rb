describe GbConceptMigrator do
  let(:m3_concept)  { create(:concept) }
  let(:add_update_params) { { :model_name => 'Concept', :id => m3_concept.id, :action => 'add_update' } }

  describe 'add_update model action' do
    it 'creates a new gradebook Concept if it does not exist' do
      gb_migrator = described_class.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy
      new_gb_concept = ::GradebookEngine::Strand.find(m3_concept.id)
      expect(new_gb_concept.name).to eql(m3_concept.name)
      expect(new_gb_concept.color).to eql(m3_concept.background_color)
      expect(new_gb_concept.rank).to eq(m3_concept.rank+1)
    end

    it 'updates existing gradebook Lesson record' do
      gb_concept = ::GradebookEngine::Strand.new()
      gb_concept.id = m3_concept.id
      gb_concept.name = m3_concept.name
      gb_concept.color = m3_concept.background_color
      gb_concept.rank = m3_concept.rank
      gb_concept.save
      gb_concept = ::GradebookEngine::Strand.find(m3_concept.id)
      expect(gb_concept.id).to eql(m3_concept.id)
      expect(gb_concept.name).to eq(m3_concept.name)
      expect(gb_concept.rank).to eq(m3_concept.rank+1)
      m3_concept.rank = m3_concept.rank + 2
      m3_concept.save
      gb_migrator = described_class.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy
      updated_gb_concept = ::GradebookEngine::Strand.find(m3_concept.id)
      expect(updated_gb_concept.rank).to eql(m3_concept.rank + 1)
    end
  end

  describe 'delete model action' do
    it 'deletes an existing gradebook Lesson record' do
      gb_concept = ::GradebookEngine::Strand.new()
      gb_concept.id = m3_concept.id
      gb_concept.rank = m3_concept.rank
      gb_concept.save
      gb_concept = ::GradebookEngine::Strand.find(m3_concept.id)
      expect(gb_concept.id).to eql(m3_concept.id)
      gb_migrator = described_class.new(m3_concept.gb_deletion_opts)
      result = gb_migrator.update_object
      expect(result).to be_nil
      expect{ ::GradebookEngine::Strand.find(m3_concept.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
