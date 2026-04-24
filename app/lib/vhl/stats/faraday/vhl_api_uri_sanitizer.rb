module Vhl
  module Stats
    module Faraday
      class VhlApiUriSanitizer < UriSanitizer
        HOST_MATCHER = /api\.maestro\.vhlcentral\.com$/.freeze

        def sanitize(host, uri)
          return uri unless self.class.host_matches?(host)

          # remove params
          uri, _params = uri.split('?')
          # convert guids and ids
          uri.gsub(%r{/\w+\-\w+\-\w+\-\w+\-\w+}, '/_guid_').gsub(%r{/\d+}, '/_id_')
        end
      end
    end
  end
end
