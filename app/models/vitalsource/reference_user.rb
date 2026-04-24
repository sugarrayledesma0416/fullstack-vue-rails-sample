module Vitalsource
  class ReferenceUser < BaseConsumer
    attr_reader :user

    USER_EXISTS_ERROR_CODE = 904

    def initialize(user)
      @user = user
    end

    def access_token(&block)
      if VitalsourceRedemption.where(user_id: user).exists?
        token_for_existing_user(&block)
      else
        response = client.post('v3/users.xml', user_creation_xml)
        if response.is_a?(Nokogiri::XML::Document)
          yield response.at('user/access-token').content
        elsif response[:error_code] == USER_EXISTS_ERROR_CODE
          token_for_existing_user(&block)
        else
          response
        end
      end
    end

    def token_for_existing_user(&block)
      response = client.post('v3/credentials.xml', credentials_xml)
      if response.is_a?(Nokogiri::XML::Document)
        error_node = response.at('credentials/error')
        if error_node
          { error_code: error_node['code'].to_i,
            error_message: error_node['message'] }
        else
          credential_node = response.at('credentials/credential')
          yield credential_node['access-token']
        end
      else
        response
      end
    end

    private def user_creation_xml
      new_xml_body.user do |user_node|
        user_node.reference(user.id)
        user_node.tag!('first-name', user.first_name)
        user_node.tag!('last-name', user.last_name)
      end
    end

    private def credentials_xml
      new_xml_body.credentials do |credentials_node|
        credentials_node.credential('', reference: user.id)
      end
    end
  end
end
