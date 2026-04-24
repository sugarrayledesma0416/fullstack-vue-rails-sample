module Portfolio
  module SyncService
    PORTFOLIO_CONFIG = if %w[live staging qa].include?(Rails.env)
                         {
                           admin_web_token: ENV.fetch('PORTFOLIO_ADMIN_TOKEN'),
                           domain_url: ENV.fetch('PORTFOLIO_DOMAIN_URL')
                         }
                       else
                         Rails.configuration.portfolio || {}
                       end

    PORTFOLIO_FUNCTIONS = {
      create_group: 'mahara_group_create_groups',
      create_institute: 'mahara_institution_create_institute',
      create_service: 'mahara_institution_create_service',
      create_webtoken: 'mahara_institution_create_webtoken',
      create_users: 'mahara_user_create_users',
      delete_group: 'mahara_group_delete_groups',
      get_group_by_id: 'mahara_group_get_groups_by_id',
      update_group_details: 'mahara_group_update_groups_details',
      update_group_members: 'mahara_group_update_group_members',
      bulk_upload_files: 'mahara_bulk_upload_files',
      institution_add_members: 'mahara_institution_add_members',
      bulk_groups_resync: 'mahara_group_bulk_groups_resync'
    }.freeze
    CONTENT_TYPE = 'application/x-www-form-urlencoded'.freeze
    USER_AGENT = 'VHL'.freeze
    SERVICE_FUNCTIONS = %w[
      mahara_group_create_groups
      mahara_user_create_users
      mahara_group_delete_groups
      mahara_group_update_groups_details
      mahara_group_update_group_members
      mahara_group_get_groups_by_id
      mahara_bulk_upload_files
      mahara_group_bulk_groups_resync
    ].freeze

    def create_institute_with_token(school)
      params = {
        'wstoken' => PORTFOLIO_CONFIG[:admin_web_token],
        'wsfunction' => PORTFOLIO_FUNCTIONS[:create_institute],
        'institute[displayname]' => school.name,
        'institute[theme]' => 'vhl',
        'institute[adminUsername]' => 'admin'
      }
      institute_response = process_http_request(params)
      service_response = create_service(institute_response)
      token_response = create_token(institute_response, service_response)
      update_school(school, institute_response, token_response)
    end

    def create_service(institute_response)
      params = {
        'wstoken' => PORTFOLIO_CONFIG[:admin_web_token],
        'wsfunction' => PORTFOLIO_FUNCTIONS[:create_service],
        'service[name]' => "#{institute_response['displayname']} Service",
        'service[shortname]' => "#{institute_response['name']}service",
        'service[component]' => 'module-vhl',
        'service[tokenusers]' => 1
      }
      SERVICE_FUNCTIONS.each_with_index do |fn, index|
        params["service[functionnames][#{index}][name]"] = fn
      end
      process_http_request(params)
    end

    def create_token(institute, service)
      params = {
        'wstoken' => PORTFOLIO_CONFIG[:admin_web_token],
        'wsfunction' => PORTFOLIO_FUNCTIONS[:create_webtoken],
        'adminusername' => 'admin',
        'instituteName' => institute['name'],
        'serviceID' => service['id']
      }
      process_http_request(params)
    end

    private def update_school(school, institute_response, token_response)
      school_config = school.school_config
      if school_config
        school_config.update(
          web_token: token_response['webToken'],
          institute_short_name: institute_response['name']
        )
      else
        SchoolConfig.create(
          school_id: school.id,
          web_token: token_response['webToken'],
          institute_short_name: institute_response['name']
        )
      end
    end

    def bulk_groups_resync(course, school_config, program)
      logo_url = program&.logo_media&.public_url_for_arc
      cover_image_url = get_program_cover_image(program)
      params = {
        'wstoken' => school_config.web_token,
        'wsfunction' => PORTFOLIO_FUNCTIONS[:bulk_groups_resync]
      }
      course.sections.each_with_index do |section, index|
        params["groups[#{index}][name]"] = "#{course.name} - #{section.name}"
        params["groups[#{index}][shortname]"] = section.guid
        params["groups[#{index}][institution]"] = school_config.institute_short_name
        params["groups[#{index}][grouptype]"] = 'standard'
        params["groups[#{index}][logo]"] = logo_url
        params["groups[#{index}][coverimage]"] = cover_image_url
        params["groups[#{index}][open]"] = '1'

        build_members_params(params, index, section.section_instructors)
      end
      process_http_request(params)
    end

    def create_group(section, instructors, program)
      portfolio_group_name = "#{section.course.name} - #{section.name}"
      school_config = section.school.reload.school_config
      create_user_accounts(instructors)
      attach_users_to_institute(school_config, instructors)
      params = {
        'wstoken' => school_config.web_token,
        'wsfunction' => PORTFOLIO_FUNCTIONS[:create_group],
        'groups[0][name]' => portfolio_group_name,
        'groups[0][shortname]' => section.guid,
        'groups[0][institution]' => school_config.institute_short_name,
        'groups[0][description]' => section.additional_info,
        'groups[0][grouptype]' => 'standard',
        'groups[0][logo]' => program&.logo_media&.public_url_for_arc,
        'groups[0][coverimage]' => get_program_cover_image(program),
        'groups[0][open]' => '1'
      }
      instructors.each_with_index do |user, index|
        params["groups[0][members][#{index}][username]"] = user.username
        params["groups[0][members][#{index}][role]"] = 'admin'
      end
      process_http_request(params)
    end

    def delete_group(section_guid, school_config)
      params = {
        'wstoken' => school_config.web_token,
        'wsfunction' => PORTFOLIO_FUNCTIONS[:delete_group],
        'groups[0][shortname]' => section_guid,
        'groups[0][institution]' => school_config.institute_short_name
      }
      process_http_request(params)
    end

    def update_group_details(school_config, section, group_id)
      portfolio_group_name = "#{section.course.name} - #{section.name}"
      params = {
        'wstoken' => school_config.web_token,
        'wsfunction' => PORTFOLIO_FUNCTIONS[:update_group_details],
        'groups[0][id]' => group_id,
        'groups[0][name]' => portfolio_group_name,
        'groups[0][shortname]' => section.guid,
        'groups[0][description]' => section.additional_info || "Group for #{portfolio_group_name}",
        'groups[0][institution]' => school_config.institute_short_name
      }
      process_http_request(params)
    end

    def bulk_update_groups_details(school_config, sections, course)
      params = {
        'wstoken' => school_config.web_token,
        'wsfunction' => PORTFOLIO_FUNCTIONS[:update_group_details]
      }
      sections.each_with_index do |section, index|
        params["groups[#{index}][name]"] = "#{course.name} - #{section.name}"
        params["groups[#{index}][shortname]"] = section.guid
        params["groups[#{index}][description]"] = section.additional_info
        params["groups[#{index}][institution]"] = school_config.institute_short_name
      end
      process_http_request(params)
    end

    def get_group_by_id(school_config, section_guid)
      params = {
        'wstoken' => school_config.web_token,
        'wsfunction' => PORTFOLIO_FUNCTIONS[:get_group_by_id],
        'groups[0][shortname]' => section_guid,
        'groups[0][institution]' => school_config.institute_short_name
      }
      process_http_request(params)
    end

    def update_group_members(school_config, shortname, added_users, removed_users, role)
      users = User.where(username: added_users + removed_users)
      users_to_add = User.where(username: added_users)
      return if users.blank?

      if users_to_add.present?
        create_user_accounts(users_to_add)
        attach_users_to_institute(school_config, users_to_add)
      end
      params = {
        'wstoken' => school_config.web_token,
        'wsfunction' => PORTFOLIO_FUNCTIONS[:update_group_members],
        'groups[0][shortname]' => shortname,
        'groups[0][institution]' => school_config.institute_short_name
      }
      users.each_with_index do |user, index|
        action = if added_users.include? user.username
                   'add'
                 else
                   'remove'
                 end
        params["groups[0][members][#{index}][guid]"] = user.guid
        params["groups[0][members][#{index}][role]"] = role
        params["groups[0][members][#{index}][action]"] = action
      end
      process_http_request(params)
    end

    def create_user_accounts(users)
      params = {
        'wstoken' => PORTFOLIO_CONFIG[:admin_web_token],
        'wsfunction' => PORTFOLIO_FUNCTIONS[:create_users]
      }

      users.each_with_index do |user, index|
        params["users[#{index}][username]"] = user.username
        params["users[#{index}][firstname]"] = user.first_name
        params["users[#{index}][lastname]"] = user.last_name
        params["users[#{index}][guid]"] = user.guid
        params["users[#{index}][institution]"] = 'ssoproxy'
        params["users[#{index}][auth]"] = 'saml'
        params["users[#{index}][password]"] = SecureRandom.urlsafe_base64(12)
      end
      process_http_request(params)
    end

    def upload_bulk_artifacts(attempt, section, activity, user, files, school)
      school_config = school.school_config

      params = {
        'wstoken' => school_config.web_token,
        'wsfunction' => PORTFOLIO_FUNCTIONS[:bulk_upload_files],
        'username' => user.username,
        'externalsource' => 'M3',
        'foldername' => folder_name(section&.course, activity)
      }
      files.each_with_index do |file, index|
        params["filetouploads[#{index}][title]"] = file[:name]
        params["filetouploads[#{index}][description]"] = "Artifact type - #{file[:type]}"
      end
      # We create the missing user so that artifacts can be linked to user.
      # User would get linked to institution and group
      # when user tries to access portfolio app via sso.
      create_user_accounts([user]) if user.student?
      process_upload_file_http_request(params, attempt, files)
    end

    def attach_users_to_institute(school_config, users)
      params = {
        'wstoken' => PORTFOLIO_CONFIG[:admin_web_token],
        'wsfunction' => PORTFOLIO_FUNCTIONS[:institution_add_members],
        'institution' => school_config.institute_short_name
      }
      users.each_with_index do |user, index|
        params["users[#{index}][username]"] = user.username
      end
      process_http_request(params)
    end

    def sync_institute(school)
      school.school_config&.web_token.nil? && create_institute_with_token(school)
    end

    private def folder_name(course, activity)
      lesson_label = sanitize_path(activity.lesson.label)
      program_title = sanitize_path(activity.program&.title || 'vhl')
      activity_title = sanitize_path(activity.title)

      if course
        "#{program_title}/#{sanitize_path(course.name)}/#{lesson_label}/#{activity_title}"
      else
        "#{program_title}/#{lesson_label}"
      end
    end

    private def build_members_params(params, index, section_instructors)
      instructors = User.where(id: section_instructors.pluck('user_id'))
      instructors.each_with_index do |user, idx|
        build_member_params(params, index, idx, user)
      end
    end

    private def build_member_params(params, index, idx, user)
      params["groups[#{index}][members][#{idx}][username]"] = user.username
      params["groups[#{index}][members][#{idx}][firstname]"] = user.first_name
      params["groups[#{index}][members][#{idx}][lastname]"] = user.last_name
      params["groups[#{index}][members][#{idx}][guid]"] = user.guid
      params["groups[#{index}][members][#{idx}][institution]"] = 'ssoproxy'
      params["groups[#{index}][members][#{idx}][auth]"] = 'saml'
      params["groups[#{index}][members][#{idx}][password]"] = SecureRandom.urlsafe_base64(12)
      params["groups[#{index}][members][#{idx}][role]"] = 'admin'
    end

    private def sanitize_path(path)
      return '' if path.blank?

      path.downcase.squish!
      path.gsub!(%r{[<>|/\\()&;#?*–]}, '-')
      path.gsub!(':', '')
      path.gsub(/\s/, '_')
    end

    private def process_http_request(params)
      url = portfolio_webservice_url
      http = Net::HTTP.new(url.host, url.port)
      if url.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      request = Net::HTTP::Post.new(url.path)
      request['Content-Type'] = CONTENT_TYPE
      request['User-Agent'] = USER_AGENT
      request['Accept'] = 'application/json'
      request.set_form_data(params)
      response = http.request(request)

      handle_response(response)
    end

    private def get_program_cover_image(program)
      request_url = "#{UA_URL}/portfolio/api/program_cover_image_url/#{program.id}"
      url = URI.parse(request_url)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true if url.scheme == 'https'
      request = Net::HTTP::Get.new(url.path)
      response = http.request(request)

      handle_response(response)['url']
    end

    private def process_upload_file_http_request(params, attempt, files)
      url = portfolio_webservice_url
      boundary = attempt.id.to_s
      http = Net::HTTP.new(url.host, url.port)
      if url.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      request = Net::HTTP::Post.new(url)
      request['Accept'] = 'application/json'
      request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
      request.body = bulk_upload_request_body(boundary, params, files)
      begin
        response = http.request(request)
        handle_upload_artifact_response(attempt, response)
      rescue StandardError => e
        attempt.attempt_config_attributes = {
          artifact_sharing_status: 'failed'
        }
        raise PortfolioApiError, log_exception(e)
      end
    end

    private def handle_upload_artifact_response(attempt, response)
      parsed_response = JSON.parse(response&.body)
      return if parsed_response.nil?

      raise PortfolioApiError, log_error(response) if
      !parsed_response.is_a?(Array) &&
      parsed_response['error']

      log_info(response)
      value = parsed_response['failed'].empty? ? 'success' : 'partial'
      attempt.attempt_config_attributes = {
        artifact_sharing_status: value
      }
      parsed_response
    end

    private def handle_response(response)
      parsed_response = JSON.parse(response&.body)
      return if parsed_response.nil?

      raise PortfolioApiError, log_error(response) if
      !parsed_response.is_a?(Array) &&
      parsed_response['error']

      log_info(response)
      parsed_response
    end

    private def bulk_upload_request_body(boundary, params, files)
      request_body = ''

      params.each do |key, value|
        request_body += <<~BODY
          --#{boundary}\r
          Content-Disposition: form-data; name="#{key}"\r
          \r
          #{value}\r
        BODY
      end

      files.each_with_index do |file, index|
        file_content = file[:file_content].force_encoding('UTF-8')
        request_body += <<~BODY
          --#{boundary}\r
          Content-Disposition: form-data; name="filetouploads[#{index}][file]"; filename="#{file[:name]}"\r
          Content-Type: #{file[:content_type]}\r
          \r
          #{file_content}\r
        BODY
      end
      request_body += "--#{boundary}--\r"
      request_body
    end

    private def portfolio_webservice_url
      domain_url = PORTFOLIO_CONFIG[:domain_url] || ''
      @portfolio_webservice_url ||= URI.parse(
        "#{domain_url}/webservice/rest/server.php"
      )
    end

    private def log_exception(exception)
      err_msg = exception.message
      Sidekiq.logger.info(err_msg)
      err_msg
    end

    private def log_error(response)
      err_msg = "HTTP Request Failed & Status Code: #{response&.code} " \
                "& Response Body:\n#{response&.body}"
      Sidekiq.logger.error(err_msg)
      err_msg
    end

    private def log_info(response)
      Sidekiq.logger.info(
        "HTTP Status Code: #{response.code} " \
        "& Response Body:\n#{response&.body}"
      )
    end
  end
end
