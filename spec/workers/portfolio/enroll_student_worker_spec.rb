describe Portfolio::EnrollStudentWorker, type: :worker do
  include PortfolioBuilder

  let(:student) { create(:student) }
  let(:school_config) { create(:school_config_with_portfolio) }
  let(:section) {
    create(
      :section,
      school: school_config.school,
      additional_info: 'Sample'
    )
  }
  let(:enrollment) { create(:enrollment, section:, user: student) }
  let(:worker) { described_class.new }

  describe '#perform' do
    before do
      stub_portfolio_request('mahara_group_update_group_members', "null\n")
      create_user_response = "[{\"id\":1,\"user\":\"#{student.username}\"}]\n"
      stub_portfolio_request('mahara_user_create_users', create_user_response)
      stub_portfolio_request('mahara_institution_add_members', "null\n")
    end

    it 'syncs the student added to the section to the group in portfolio.' do
      described_class.new.perform(section.id, [student.username])
      expect(
        a_request(:post,
                  "#{Rails.configuration.portfolio[:domain_url]}/webservice/rest/server.php").with(
                    body: URI.encode_www_form(
                      {
                        'wstoken' => school_config.web_token,
                        'wsfunction' => 'mahara_group_update_group_members',
                        'groups[0][shortname]' => section.guid,
                        'groups[0][institution]' => school_config.institute_short_name,
                        'groups[0][members][0][guid]' => student.guid,
                        'groups[0][members][0][role]' => 'member',
                        'groups[0][members][0][action]' => 'add'
                      }
                    )
                  )
      ).to have_been_made.once
    end
  end
end
