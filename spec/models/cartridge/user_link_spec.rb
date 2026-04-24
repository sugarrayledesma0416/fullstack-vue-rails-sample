describe Cartridge::UserLink do
  describe 'dangerfield_reject_if' do
    let(:user) { create(:user) }
    let(:school) { create(:school) }
    let(:valid_attrs) do
      {
        'sync_token' => 123_456,
        'user_guid' => user.guid,
        'school_guid' => school.guid,
        'request_id' => SecureRandom.uuid,
        'external_user_id' => 'student_1',
        'guid' => SecureRandom.uuid,
        'contexts_owner' => true
      }
    end
    let(:user_link) { described_class.new }

    it 'accepts new instance if the associated user and the associated school exist' do
      enable_dangerfield do
        described_class.dangerfield_update_attributes(valid_attrs, user_link)
        expect(user_link.guid).not_to be_nil
      end
    end

    it 'rejects new instance if the associated user does not exist' do
      enable_dangerfield do
        described_class.dangerfield_update_attributes(
          valid_attrs.merge('user_guid' => 'invalid guid'),
          user_link
        )
        expect(user_link.guid).to be_nil
      end
    end

    it 'rejects new instance if there is no user_guid attribute in the params' do
      enable_dangerfield do
        described_class.dangerfield_update_attributes(
          valid_attrs.except('user_guid'),
          user_link
        )
        expect(user_link.guid).to be_nil
      end
    end

    it 'rejects new instance if the associated school does not exist' do
      enable_dangerfield do
        described_class.dangerfield_update_attributes(
          valid_attrs.merge('school_guid' => 'invalid guid'),
          user_link
        )
        expect(user_link.guid).to be_nil
      end
    end

    it 'rejects new instance if there is no school_guid attribute ' \
       'in the params' do
      enable_dangerfield do
        described_class.dangerfield_update_attributes(
          valid_attrs.except('school_guid'),
          user_link
        )
        expect(user_link.guid).to be_nil
      end
    end
  end
end
