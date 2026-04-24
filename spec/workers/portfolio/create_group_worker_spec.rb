describe Portfolio::CreateGroupWorker, type: :worker do
  include PortfolioBuilder

  let(:instructor_1) { create(:instructor) }
  let(:instructors) { [instructor_1] }
  let(:school_config) { create(:school_config_with_portfolio) }
  let(:section) { create(:section, school: school_config.school) }
  let(:worker) { described_class.new }
  let(:program_cover_image_url) { "#{UA_URL}/portfolio/api/program_cover_image_url/#{section.program.id}" }

  def stub_program_cover_image_request
    stub_request(:get, program_cover_image_url).
      to_return(:status => 200, :body => {}.to_json, :headers => {})
  end

  describe '#perform' do
    it 'creates a group with instructor as group admins' do
      create_group_response = "[{\"id\":4,\"name\":\"#{section.name} 5884e585\"}]\n"
      create_user_response = "[{\"id\":1,\"user\":\"#{instructor_1.username}\"}]\n"
      stub_portfolio_request('mahara_group_create_groups', create_group_response)
      stub_portfolio_request('mahara_user_create_users', create_user_response)
      stub_portfolio_request('mahara_institution_add_members', "null\n")
      stub_program_cover_image_request

      expect(
        described_class.new.perform(section.id, instructors.map(&:id))
      ).to eq(JSON.parse(create_group_response))
    end
  end
end
