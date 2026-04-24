describe Etl::GradebookImport::Category do
  let(:course_id) { create(:gb_course).id }
  let(:new_attrs) do
    {
      'accept_late_work' => true,
      'course_id' => course_id,
      'created_at' => '2012-05-31T19:12:33-04:00',
      'credit_only' => false,
      'current_scoring_ruleset_id' => 4080,
      'drop_low_scores' => 0,
      'enhanced_feedback_disabled' => false,
      'group_name' => nil,
      'id' => 25,
      'is_archived' => false,
      'label_id' => nil,
      'late_work_penalty' => 'percent_per_day',
      'max_ attempts' => 2,
      'name' => 'Homework',
      'penalty_percent' => 5,
      'rank' => 1,
      'updated_at' => '2012-08-29T12:03:17-04:00',
      'weighting_percent' => 25
    }
  end

  let(:original_details) do
    {
      'credit_only' => false,
      'drop_low_scores' => 0,
      'late_work_penalty' => 'percent_per_day',
      'penalty_percent' => 5
    }
  end

  before do
    @update_attrs = new_attrs.merge(
      'drop_low_scores' => 1,
      'late_work_penalty' => 'flat_percent',
      'penalty_percent' => 7,
      'weighting_percent' => 20
    )
    @modified_details = original_details.merge(
      'drop_low_scores' => 1,
      'penalty_percent' => 7,
      'late_work_penalty' => 'flat_percent'
    )
  end

  describe 'import model action' do
    it 'creates a new gradebook category record when action is import' do
      @gb_import_model = described_class.new(
        GradebookEngine::Category, 'import', new_attrs
      )
      new_category = @gb_import_model.get_or_delete_record
      expect(new_category.id).to eql(25)
    end

    it 'throws a uniqueness error saving new gradebook category record with existing M3 id' do
      @gb_import_model = described_class.new(
        GradebookEngine::Category, 'import', new_attrs
      )
      new_category = @gb_import_model.get_or_delete_record
      new_category.save!
      another_new_category = @gb_import_model.get_or_delete_record
      expect { another_new_category.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'add_update model action' do
    it 'creates a new gradebook category record if it does not exist' do
      @gb_import_model = described_class.new(
        GradebookEngine::Category, 'add_update', new_attrs
      )
      new_category = @gb_import_model.get_or_delete_record
      expect(new_category.id).to eql(25)
    end

    it 'updates existing gradebook category record' do
      @gb_import_model = described_class.new(
        GradebookEngine::Category, 'add_update', new_attrs
      )
      new_category = @gb_import_model.get_or_delete_record
      new_category.save!
      new_category = ::GradebookEngine::Category.find(25)
      expect(new_category.weighting_percent).to eq(25.0)
      expect(new_category.details).to eql(original_details)
      @gb_import_model = described_class.new(
        GradebookEngine::Category, 'add_update', @update_attrs
      )
      updated_category = @gb_import_model.get_or_delete_record
      updated_category.save!
      updated_category = ::GradebookEngine::Category.find(25)
      expect(updated_category.weighting_percent).to eq(20.0)
      expect(updated_category.details).to eql(@modified_details)
    end
  end
end
