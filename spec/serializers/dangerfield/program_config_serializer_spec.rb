describe 'ProgramConfigSerializer' do
  let(:dangerfield_serializer) { described_class.new(ProgramConfig) }
  let(:program_config_json) { JSON.parse(program_config.dangerfield_serializer.to_json) }
  let(:creator) { create(:user) }

  describe 'dangerfield serializer' do
    let(:program_config) do
      create(
        :program_config,
        enable_concurrent_enrollment: true,
        creator_id: creator.id
      )
    end

    it 'add datastore_json attribute with the expected contents' do
      expect(program_config_json['datastore_json']['enable_concurrent_enrollment']).to eq(
        program_config.enable_concurrent_enrollment
      )
    end

    it 'validates that creator_id is injected into serialized object' do
      expect(program_config_json['creator_guid']).to eq(creator.guid)
    end
  end
end
