describe Etl::GradebookImport::SectionUser do
  let(:user_1_id) { create(:gb_user).id }
  let(:user_2_id) { create(:gb_user).id }
  let(:section_1_id) { create(:gb_section).id }
  let(:section_2_id) { create(:gb_section).id }
  let(:new_attrs) do
    {
      'added_by_id' => nil,
      'blocked' => false,
      'created_at' => '2012-06-01T10:42:51-04:00',
      'dropped_at' => nil,
      'dropped_by_id' => nil,
      'guid' => '1813485',
      'id' => 1813,
      'inactive' => false,
      'request_id' => nil,
      'section_id' => section_1_id,
      'section_transferred_to' => nil,
      'state' => 'marked_complete',
      'sufficient_access' => true,
      'sync_token' => 0,
      'transferred_from' => nil,
      'updated_at' => '2012-08-23T17:18:19-04:00',
      'user_id' => user_1_id
    }
  end

  describe 'import model action' do
    it 'creates a new gradebook SectionUser record when action is import' do
      gb_import_model = described_class.new(
        GradebookEngine::SectionUser, 'import', new_attrs
      )
      new_section_user = gb_import_model.get_or_delete_record
      expect(new_section_user.section_id).to eql(section_1_id)
      expect(new_section_user.user_id).to eql(user_1_id)
    end

    it 'throws uniqueness error saving new gradebook SectionUser record with existing primary key' do
      gb_import_model = described_class.new(
        GradebookEngine::SectionUser, 'import', new_attrs
      )
      new_section_user = gb_import_model.get_or_delete_record
      new_section_user.save!
      another_new_section_user = gb_import_model.get_or_delete_record
      expect { another_new_section_user.save }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'add_update model action' do
    it 'creates a new gradebook SectionUser record if it does not exist' do
      gb_import_model =  described_class.new(
        GradebookEngine::SectionUser, 'add_update', new_attrs
      )
      new_section_user = gb_import_model.get_or_delete_record
      expect(new_section_user.section_id).to eql(section_1_id)
      expect(new_section_user.user_id).to eql(user_1_id)
    end
  end

  describe 'delete model action' do
    it 'deletes an existing gradebook SectionUser' do
      gb_import_model = described_class.new(
        GradebookEngine::SectionUser, 'import', new_attrs
      )
      new_su_1 = gb_import_model.get_or_delete_record
      new_su_1.save!
      another_su_attrs = new_attrs.merge(
        'section_id' => section_1_id,
        'user_id' => user_2_id
      )
      gb_import_model = described_class.new(
        GradebookEngine::SectionUser, 'import', another_su_attrs
      )
      new_su_2 = gb_import_model.get_or_delete_record
      new_su_2.save!
      another_su_attrs = new_attrs.merge(
        'section_id' => section_2_id,
        'user_id' => user_1_id
      )
      gb_import_model = described_class.new(
        GradebookEngine::SectionUser, 'import', another_su_attrs
      )
      new_su_3 = gb_import_model.get_or_delete_record
      new_su_3.save!
      expect(::GradebookEngine::SectionUser.all.count).to eq 3
      delete_attrs = new_attrs.merge(
        'section_id' => section_1_id,
        'user_id' => user_1_id
      )
      gb_import_model = described_class.new(
        GradebookEngine::SectionUser, 'delete', delete_attrs
      )
      deleted_su = gb_import_model.get_or_delete_record
      expect(deleted_su).to be_nil
      expect(::GradebookEngine::SectionUser.all.count).to eq 2
    end
  end
end
