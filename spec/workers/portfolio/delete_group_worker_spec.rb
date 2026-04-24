describe Portfolio::DeleteGroupWorker, type: :worker do
  include PortfolioBuilder

  let(:school_config) { create(:school_config_with_portfolio) }
  let(:section) { create(:section, school: school_config.school) }
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'deletes a group when section from VHL is removed' do
      delete_group_response = "null\n"
      stub_portfolio_request('mahara_group_delete_groups', delete_group_response)
      described_class.new.perform(section.guid, school_config.school.id)

      expect(a_request(
        :post,
        "#{Rails.configuration.portfolio[:domain_url]}/webservice/rest/server.php"
      ).with(
        body: URI.encode_www_form(
          {
            'wstoken' => school_config.web_token,
            'wsfunction' => 'mahara_group_delete_groups',
            'groups[0][shortname]' => section.guid,
            'groups[0][institution]' => school_config.institute_short_name
          }
        )
      )).to have_been_made.once
    end
  end
end
