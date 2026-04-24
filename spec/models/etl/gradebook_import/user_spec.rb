describe Etl::GradebookImport::User do
  let(:new_attrs) do
    {
      'active' => true,
      'archived' => false,
      'created_at' => '2010-12-13T15:40:42-05:00',
      'display_email' => false,
      'email' => 'jdoe_student@vistahigherlearning.com',
      'fake' => false,
      'first_name' => 'Joseph',
      'gender' => 'Male',
      'guid' => '830639',
      'id' => 830639,
      'last_name' => 'Does',
      'preferred_time_zone' => nil,
      'request_id' => nil,
      'salesforce_id' => nil,
      'slx_contact_id' => nil,
      'student_id' => '8675309',
      'sync_token' => 0,
      'time_zone' => 'Arizona',
      'updated_at' => '2015-07-21T18:56:37-04:00',
      'username' => 'jmunoz_student',
      'year_of_birth' => 2010
    }
  end

  let(:update_attrs) { new_attrs.merge('first_name' => 'John',
                                       'last_name' => 'Doe',
                                       'fake' => false) }

  describe 'import model action' do
    it 'creates a new gradebook user record when action is import' do
      gb_import_model = described_class.new(GradebookEngine::User, 'import', new_attrs)
      new_user = gb_import_model.get_or_delete_record
      expect(new_user.id).to eql(830639)
    end

    it 'throws uniqueness error saving new gradebook user record with existing M3 id' do
      gb_import_model = described_class.new(GradebookEngine::User, 'import', new_attrs)
      new_user = gb_import_model.get_or_delete_record
      new_user.save
      another_new_user = gb_import_model.get_or_delete_record
      expect { another_new_user.save }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'add_update model action' do
    it 'creates a new gradebook user record if it does not exist' do
      gb_import_model = described_class.new(GradebookEngine::User, 'add_update', new_attrs)
      new_user = gb_import_model.get_or_delete_record
      expect(new_user.id).to eql(830639)
    end

    it 'updates existing gradebook user record' do
      gb_import_model = described_class.new(GradebookEngine::User, 'add_update', new_attrs)
      new_user = gb_import_model.get_or_delete_record
      new_user.save
      new_user = ::GradebookEngine::User.find(830639)
      expect(new_user.first_name).to eql('Joseph')
      expect(new_user.last_name).to eql('Does')
      gb_import_model = described_class.new(GradebookEngine::User, 'add_update', update_attrs)
      updated_user = gb_import_model.get_or_delete_record
      updated_user.save
      updated_user = ::GradebookEngine::User.find(830639)
      expect(updated_user.first_name).to eql('John')
      expect(updated_user.last_name).to eql('Doe')
    end
  end
end
