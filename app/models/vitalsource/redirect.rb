module Vitalsource
  class Redirect < BaseConsumer
    attr_reader :book_id

    def initialize(access_token, book_id)
      @access_token = access_token
      @book_id = book_id
    end

    def sso_url
      response = client.post('v3/redirects.xml', redirection_xml)
      if response.is_a?(Nokogiri::XML::Document)
        response.at('redirect')['auto-signin']
      else
        response
      end
    end

    private def redirection_xml
      new_xml_body.redirect do |redirect_node|
        redirect_node.destination("#{config.bookshelf_url}/#{book_id}")
      end
    end
  end
end
