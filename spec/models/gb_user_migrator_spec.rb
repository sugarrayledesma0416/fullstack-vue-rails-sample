describe GbUserMigrator do
  let(:m3_user)  { create(:user, first_name: 'Test',
                                 last_name:  'User',
                                 guid:       'hello-my-name-is-guid-how-are-you') }
  let(:add_update_params) { { :model_name => 'User', :id => m3_user.id, :action => 'add_update' } }

  describe 'add_update model action' do
    it 'creates a new gradebook user record if it does not exist' do
      gb_migrator = described_class.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy
      new_gb_user = ::GradebookEngine::User.find(m3_user.id)
      expect(new_gb_user.first_name).to eql(m3_user.first_name)
      expect(new_gb_user.last_name).to eql(m3_user.last_name)
      expect(new_gb_user.guid).to eql(m3_user.guid)
    end

    it 'updates existing gradebook user record' do
      gb_user = ::GradebookEngine::User.new()
      gb_user.first_name = 'Test'
      gb_user.id = m3_user.id
      gb_user.save
      gb_user = ::GradebookEngine::User.find(m3_user.id)
      expect(gb_user.first_name).to eql('Test')
      m3_user.first_name = 'Modified'
      m3_user.save
      gb_migrator = described_class.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy
      updated_gb_user = ::GradebookEngine::User.find(m3_user.id)
      expect(updated_gb_user.first_name).to eql('Modified')
    end
  end

   describe 'delete model action' do
     it 'deletes an existing gradebook User record' do
       gb_user = ::GradebookEngine::User.new()
       gb_user.first_name = 'Test'
       gb_user.id = m3_user.id
       gb_user.save
       gb_user = ::GradebookEngine::User.find(m3_user.id)
       expect(gb_user.first_name).to eql('Test')
       gb_migrator = described_class.new(m3_user.gb_deletion_opts)
       result = gb_migrator.update_object
       expect(result).to be_nil
       expect{ ::GradebookEngine::User.find(m3_user.id) }.to raise_error(ActiveRecord::RecordNotFound)
     end
   end
end
