module Vhl
  module Stats
    module Faraday
      class SubmissionsUriSanitizer < UriSanitizer
        HOST_MATCHER = /submissions\.maestro\.vhlcentral\.com$/.freeze

        def sanitize(host, uri)
          return uri unless self.class.host_matches?(host)

          # remove params
          uri, _params = uri.split('?')
          uri
        end
      end
    end
  end
end
