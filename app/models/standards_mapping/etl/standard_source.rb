module StandardsMapping
  module Etl
    class StandardSource
      # we need to check if this is an initial load vs an update
      # and grab records accordingly; we should have the load_type
      # and date of last upload in the params, as well as the batch size
      def initialize(params)
        @params = params
        # for first draft assume load type is 'initial';
        # get all Standard records - need this class and related classes
        puts "Processing all Standard records count:#{Standard.count}"
        # Eventually we will use the upload_type and date to select the standards to upload.
        @records = Standard.all.includes(:standard_set)
      end

      #Kiba will call this to get each record for processing
      def each
        @records.each do |record|
          yield record
        end
      end
    end
  end
end