describe Cartridge::Consumer do
  describe 'dangerfield_reject_if' do
    let(:school) { create(:school) }
    let(:valid_attrs) do
      {
        'sync_token' => 123_456,
        'school_guid' => school.guid,
        'request_id' => SecureRandom.uuid,
        'name' => 'some name',
        'key' => SecureRandom.base64(40),
        'secret' => SecureRandom.base64(40),
        'guid' => SecureRandom.uuid
      }
    end
    let(:consumer) { described_class.new }

    it 'accepts new instance if the associated school exists' do
      enable_dangerfield do
        described_class.dangerfield_update_attributes(valid_attrs, consumer)
        expect(consumer.guid).not_to be_nil
      end
    end

    it 'rejects new instance if the associated school does not exist' do
      enable_dangerfield do
        described_class.dangerfield_update_attributes(
          valid_attrs.merge('school_guid' => 'invalid guid'),
          consumer
        )
        expect(consumer.guid).to be_nil
      end
    end

    it 'rejects new instance if there is no school_guid attribute in the params' do
      enable_dangerfield do
        described_class.dangerfield_update_attributes(
          valid_attrs.except('school_guid'),
          consumer
        )
        expect(consumer.guid).to be_nil
      end
    end
  end
end
