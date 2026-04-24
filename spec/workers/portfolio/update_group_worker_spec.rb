require 'rails_helper'

describe Portfolio::UpdateGroupWorker, type: :worker do
  let(:instructor_1) { create(:instructor) }
  let(:instructor_2) { create(:instructor) }
  let(:school_config) { create(:school_config_with_portfolio) }
  let(:section) do
    create(
      :section,
      school: school_config.school,
      instructor: instructor_1,
      additional_info: 'Sample'
    )
  end
  let(:old_section_name) { "#{section.course.name} - #{section.name}" }
  let(:worker) { described_class.new }
  let(:webservice_url) do
    "#{Rails.configuration.portfolio[:domain_url]}/webservice/rest/server.php"
  end


  def stub_portfolio_request(request_type, stub_response)
    stub_request(
      :post, %r{http://.*/webservice/rest/server.php}
    ).with do |request|
      body_params = URI.decode_www_form(request.body)
      param_value = body_params.find { |key, _| key == 'wsfunction' }&.last
      param_value == request_type
    end.to_return(
      status: 200,
      body: stub_response
    )
  end

  describe '#perform when section name is updated' do
    before do
      group_details = "[{
        \"id\": 1,
        \"name\": \"#{old_section_name}\",
        \"members\": [{
          \"username\": \"#{instructor_1.username}\",
          \"role\": \"admin\"
        }]
      }]\n"
      stub_portfolio_request('mahara_group_get_groups_by_id', group_details)
      section.name = 'New Section'
      section.save
      stub_portfolio_request('mahara_group_update_groups_details', "null\n")
    end

    it 'updates the group section name if section name is updated.' do
      described_class.new.perform(section.id)
      expect(
        a_request(:post, webservice_url).with(
          body: URI.encode_www_form({
                                      'wstoken' => school_config.web_token,
                                      'wsfunction' => 'mahara_group_update_groups_details',
                                      'groups[0][id]' => 1,
                                      'groups[0][name]' => "#{section.course.name} - #{section.name}",
                                      'groups[0][shortname]' => section.guid,
                                      'groups[0][description]' => section.additional_info,
                                      'groups[0][institution]' => school_config.institute_short_name
                                    })
        )
      ).to have_been_made.once
    end
  end

  describe '#perform when section instructors list is updated.' do
    before do
      group_details = "[{
        \"id\": 1,
        \"description\": \"#{section.additional_info}\",
        \"name\": \"#{section.name}\",
        \"members\": [{
          \"username\": \"#{instructor_1.username}\",
          \"role\": \"admin\"
        }]
      }]\n"
      stub_portfolio_request('mahara_group_get_groups_by_id', group_details)
      section.instructors << instructor_2
      stub_portfolio_request('mahara_group_update_group_members', "null\n")
      create_user_response = "[{\"id\":1,\"user\":\"#{instructor_1.username}\"}]\n"
      stub_portfolio_request('mahara_user_create_users', create_user_response)
      stub_portfolio_request('mahara_institution_add_members', "null\n")
    end

    it 'updates the association of members to the group.' do
      described_class.new.perform(section.id)
      expect(
        a_request(:post, webservice_url).with(
          body: URI.encode_www_form({
                                      'wstoken' => school_config.web_token,
                                      'wsfunction' => 'mahara_group_update_group_members',
                                      'groups[0][shortname]' => section.guid,
                                      'groups[0][institution]' => school_config.institute_short_name,
                                      'groups[0][members][0][guid]' => instructor_2.guid,
                                      'groups[0][members][0][role]' => 'admin',
                                      'groups[0][members][0][action]' => 'add'
                                    })
        )
      ).to have_been_made.once
    end
  end
end
