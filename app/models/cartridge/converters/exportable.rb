module Cartridge
  module Converters
    module Exportable
      VENDOR_CODE = 'Vhl Central'.freeze
      VENDOR_NAME = 'Vista Higher Learning'.freeze
      VENDOR_URL = 'https://www.vhlcentral.com'.freeze
      VENDOR_EMAIL = 'contact@vhlcentral.com'.freeze

      private def canvas_extension
        # By default, Canvas handles LTI launch URLs with query parameters by
        # including the query parameters in the URL and the post body. This
        # can result in a signature mismatch if not accounted for. The oauth_compliant
        # parameter allows an external tool provider to specify how it wants
        # Canvas to handle launch URLs with query parameters: if set to true
        # LTI query parameters will not be copied to the POST body.
        # https://canvas.instructure.com/doc/api/file.tools_xml.html
        MultiVersionCommonCartridge::Resources::BasicLtiLink::Extension.new(
          'canvas.instructure.com'
        ).tap do |extension|
          extension.properties['oauth_compliant'] = true
        end
      end

      private def secure_launch_url
        URI.join(UA_URL, "cartridge/launches/#{resource_link.resource_link_id}").to_s
      end
    end
  end
end
