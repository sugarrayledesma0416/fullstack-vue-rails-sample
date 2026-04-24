module Vitalsource
  class License < BaseConsumer
    attr_reader :book_id, :expires_on

    def initialize(access_token, book_id, expires_on)
      @access_token = access_token
      @book_id = book_id
      @expires_on = require_date(expires_on)
    end

    private def require_date(value)
      if value.is_a?(Date)
        value
      else
        raise(ArgumentError,
              "expires_on argument must be a Date, is #{value.class}")
      end
    end

    def ensure_access(&block)
      if existing_license.active?
        yield
      else
        grant_access(&block)
      end
    end

    private def existing_license
      ExistingLicense.new(@access_token, book_id)
    end

    private def grant_access(&block)
      response = client.post('v3/codes.xml', code_creation_xml)
      if response.is_a?(Nokogiri::XML::Document)
        code = response.at('codes/code').content
        redeem_code(code, &block)
      else
        response
      end
    end

    private def redeem_code(code)
      response = client.post('v3/redemptions.xml', redemption_xml(code))
      if response.is_a?(Nokogiri::XML::Document)
        yield
      else
        response
      end
    end

    private def code_creation_xml
      new_xml_body.codes(sku: book_id,
                         'license-type' => 'absdate',
                         'exp-year' => expires_on.year,
                         'exp-month' => expires_on.month,
                         'exp-day' => expires_on.day,
                         'num-codes' => 1)
    end

    private def redemption_xml(code)
      new_xml_body.redemption do |redemption_node|
        redemption_node.code(code)
      end
    end
  end
end
