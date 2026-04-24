module Vitalsource
  class ExistingLicense < BaseConsumer
    attr_reader :book_id

    def initialize(access_token, book_id)
      @access_token = access_token
      @book_id = book_id
    end

    def active?
      license_for_book && Date.parse(license_for_book['expiration']) > Date.today
    end

    private def license_for_book
      return @license_for_book if defined?(@license_for_book)
      @license_for_book = licenses.detect do |license_node|
        license_node['sku'] == book_id
      end
    end

    private def licenses
      response = client.get('v3/licenses.xml')
      if response.is_a?(Nokogiri::XML::Document)
        response.xpath('licenses/license')
      else
        raise "Vitalsource API Error #{response.inspect}"
      end
    end
  end
end
