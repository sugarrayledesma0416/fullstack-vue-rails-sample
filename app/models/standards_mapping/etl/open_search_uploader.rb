module StandardsMapping
  module Etl
    class OpenSearchUploader
      def initialize(params)
        @params = params
      end

      # call OS client API and bulk load
      # this batch of documents to the index.
      # NOTE: batch is an array of JSON blocks
      def post_batch(batch)
        # this will be called from the Kiba destination class
        # when it has collected the desired number of record
        # for batch load;
        # NOTE: records can be a mix of new and updates
        open_search_client.bulk_upload(batch)
      end

      private def open_search_client
        # sets up the HTTP endpoint connection to talk to OS
        # probably want a client class that can be shared
        # with the query API call
        # see examples that we did with OneRosterAPI calls
        #
        @open_search_client ||= OpenSearchClient.new()
      end
    end
  end
end
