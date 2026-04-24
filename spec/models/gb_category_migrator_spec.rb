describe GbCategoryMigrator do
  let(:m3_category) { create(:category, name: 'Category 1') }
  let(:add_update_params) do
    { model_name: 'Category', id: m3_category.id, action: 'add_update' }
  end
  let(:modified_details) do
    {
      'credit_only' => false,
      'drop_low_scores' => 1,
      'late_work_penalty' => 'flat_percent',
      'penalty_percent' => 5
    }
  end

  before do
    create(:gb_course, id: m3_category.course_id)
  end

  describe 'add_update model action' do
    it 'creates a new gradebook category record if it does not exist' do
      gb_migrator = described_class.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy
      new_gb_category = ::GradebookEngine::Category.find(m3_category.id)
      expect(new_gb_category.name).to eql(m3_category.name)
      expect(new_gb_category.school_id).to eq(m3_category.course.school_id)
    end

    it 'updates existing gradebook category record' do
      gb_category = ::GradebookEngine::Category.new(
        course_id: m3_category.course_id,
        id: m3_category.id,
        name: m3_category.name,
        weighting_percent: m3_category.weighting_percent
      )
      gb_category.save!
      gb_category = ::GradebookEngine::Category.find(m3_category.id)
      expect(gb_category.weighting_percent).to eq(m3_category.weighting_percent)
      expect(gb_category.details).to eq({})
      m3_category.weighting_percent = 25
      m3_category.drop_low_scores = 1
      m3_category.late_work_penalty = 'flat_percent'
      m3_category.penalty_percent = 5
      m3_category.credit_only = 0
      m3_category.save!
      gb_migrator = described_class.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy
      updated_gb_category = ::GradebookEngine::Category.find(m3_category.id)
      expect(updated_gb_category.weighting_percent).to eql(25.0)
      expect(updated_gb_category.details).to eq(modified_details)
    end
  end

  describe 'delete model action' do
    it 'deletes an existing gradebook Category record' do
      gb_category = ::GradebookEngine::Category.new(
        course_id: m3_category.course_id,
        id: m3_category.id,
        name: 'Existing M3 Category'
      )
      gb_category.save!
      gb_category = ::GradebookEngine::Category.find(m3_category.id)
      expect(gb_category.name).to eql('Existing M3 Category')
      gb_migrator = described_class.new(m3_category.gb_deletion_opts)
      result = gb_migrator.update_object
      expect(result).to be_nil
      expect do
        ::GradebookEngine::Category.find(m3_category.id)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
