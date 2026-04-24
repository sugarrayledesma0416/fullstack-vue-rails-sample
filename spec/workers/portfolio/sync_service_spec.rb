describe Portfolio::SyncService do
  include described_class
  include PortfolioBuilder
  include RspecJsContentHelpers

  let(:school_config) { create(:school_config_with_portfolio) }
  let(:instructor_1) { create(:instructor) }
  let(:student) { create(:student) }
  let(:instructors) { [instructor_1] }
  let(:section) {
    create(
      :section,
      school: school_config.school,
      additional_info: 'Sample Description'
    )
  }
  let(:enrollment) { create(:active_enrollment, section:, user: student) }
  let(:program) { create(:program_with_lessons) }
  let(:activity) { create_drop_down_table_activity(program) }
  let(:attempt) do
    create(
      :attempt_submitted,
      activity:,
      section:,
      user: student
    )
  end
  let(:webservice_url) do
    "#{Rails.configuration.portfolio[:domain_url]}/webservice/rest/server.php"
  end
  let(:program_cover_image_url) { "#{UA_URL}/portfolio/api/program_cover_image_url/#{program.id}" }

  def stub_program_cover_image_request
    stub_request(:get, program_cover_image_url)
      .to_return(:status => 200, :body => { url: '' }.to_json, :headers => {})
  end

  def stub_create_user_request
    create_user_response = "[{\"id\":1,\"user\":\"#{instructor_1.username}\"}]\n"
    stub_portfolio_request('mahara_user_create_users', create_user_response)
  end

  def stub_create_group_request
    create_group_response = "[{\"id\":4,\"name\":\"#{section.name} 5884e585\"}]\n"
    stub_portfolio_request('mahara_group_create_groups', create_group_response)
  end

  def create_drop_down_table_activity(program)
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'drop_down_table.xml'),
      program,
      grading_method: 'auto'
    )
  end

  describe '#create_user_accounts' do
    it 'creates user accounts to Portfolio Application using HTTP request.' do
      stub_create_user_request
      create_user_accounts(instructors)

      expect(
        a_request(:post, webservice_url).with(
          body: satisfy do |body|
            decoded_values = URI.decode_www_form(body)
            expect(decoded_values.to_h).to include(
              'wstoken' => 'test-token',
              'wsfunction' => 'mahara_user_create_users',
              'users[0][username]' => instructor_1.username,
              'users[0][firstname]' => instructor_1.first_name,
              'users[0][lastname]' => instructor_1.last_name,
              'users[0][institution]' => 'ssoproxy',
              'users[0][auth]' => 'saml'
            )
          end
        )
      ).to have_been_made.once
    end
  end

  describe '#create_group' do
    it 'creates a group corresponding to the section.' do
      stub_create_user_request
      stub_create_group_request
      stub_program_cover_image_request
      stub_portfolio_request('mahara_institution_add_members', "null\n")
      allow(program).to receive(:logo_media).and_return(nil)
      create_group(section, instructors, program)

      expect(
        a_request(:post, webservice_url).with(
          body: URI.encode_www_form(
            {
              'wstoken' => school_config.web_token,
              'wsfunction' => 'mahara_group_create_groups',
              'groups[0][name]' => "#{section.course.name} - #{section.name}",
              'groups[0][shortname]' => section.guid,
              'groups[0][institution]' => school_config.institute_short_name,
              'groups[0][description]' => section.additional_info,
              'groups[0][grouptype]' => 'standard',
              'groups[0][logo]' => nil,
              'groups[0][coverimage]' => '',
              'groups[0][open]' => '1',
              'groups[0][members][0][username]' => instructor_1.username,
              'groups[0][members][0][role]' => 'admin'
            }
          )
        )
      ).to have_been_made.once
    end
  end

  describe '#delete_group' do
    it 'deletes a group corresponding to the section.' do
      delete_group_response = "null\n"
      stub_portfolio_request('mahara_group_delete_groups', delete_group_response)
      delete_group(section.guid, school_config)

      expect(a_request(:post, webservice_url).with(
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

  describe '#get_group_by_id' do
    it 'gets a group specific to a section name.' do
      group_details = "[{
        \"id\": 1,
        \"name\": \"#{section.name}\",
        \"members\": [{
          \"username\": \"#{instructor_1.username}\",
          \"role\": \"admin\"
        }]
      }]\n"
      stub_portfolio_request('mahara_group_get_groups_by_id', group_details)
      get_group_by_id(school_config, section.guid)

      expect(
        a_request(:post, webservice_url).with(
          body: URI.encode_www_form(
            {
              'wstoken' => school_config.web_token,
              'wsfunction' => 'mahara_group_get_groups_by_id',
              'groups[0][shortname]' => section.guid,
              'groups[0][institution]' => school_config.institute_short_name
            }
          )
        )
      ).to have_been_made.once
    end
  end

  describe '#update_group_details' do
    it 'updates the group details.' do
      group_details = "[{
        \"id\": 1,
        \"name\": \"#{section.name}\",
        \"members\": [{
          \"username\": \"#{instructor_1.username}\",
          \"role\": \"admin\"
        }]
      }]\n"
      stub_portfolio_request('mahara_group_update_groups_details', "null\n")
      update_group_details(school_config, section, JSON.parse(group_details)[0]['id'])

      expect(
        a_request(:post, webservice_url).with(
          body: URI.encode_www_form(
            {
              'wstoken' => school_config.web_token,
              'wsfunction' => 'mahara_group_update_groups_details',
              'groups[0][id]' => 1,
              'groups[0][name]' => "#{section.course.name} - #{section.name}",
              'groups[0][shortname]' => section.guid,
              'groups[0][description]' => section.additional_info,
              'groups[0][institution]' => school_config.institute_short_name
            }
          )
        )
      ).to have_been_made.once
    end
  end

  describe '#update_group_members' do
    it 'updates the group members association.' do
      stub_portfolio_request('mahara_group_update_group_members', "null\n")
      stub_create_user_request
      stub_portfolio_request('mahara_institution_add_members', "null\n")
      update_group_members(
        school_config,
        section.guid,
        [instructor_1.username],
        [],
        'admin'
      )

      expect(
        a_request(:post, webservice_url).with(
          body: URI.encode_www_form(
            {
              'wstoken' => school_config.web_token,
              'wsfunction' => 'mahara_group_update_group_members',
              'groups[0][shortname]' => section.guid,
              'groups[0][institution]' => school_config.institute_short_name,
              'groups[0][members][0][guid]' => instructor_1.guid,
              'groups[0][members][0][role]' => 'admin',
              'groups[0][members][0][action]' => 'add'
            }
          )
        )
      ).to have_been_made.once
    end
  end

  describe '#attach_users_to_institute' do
    it 'returns the response after member attach to the institute.' do
      stub_portfolio_request('mahara_institution_add_members', "null\n")
      response = attach_users_to_institute(school_config, instructors)

      expect(response).to be_nil
    end
  end
end
