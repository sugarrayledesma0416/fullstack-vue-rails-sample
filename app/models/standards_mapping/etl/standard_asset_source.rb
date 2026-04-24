module StandardsMapping
  module Etl
    class StandardAssetSource
      # we need to check if this is an initial load vs an update
      # and grab records accordingly; we should have the load_type
      # and date of last upload in the params, as well as the batch size
      def initialize(params)
        params = params
        # for first draft assume load type is 'initial';
        # get all StandardAsset records - need this class and related classes
        # blocked by https://vistahl.atlassian.net/browse/MAE-64549
        puts "Processing all StandardAssets records count:#{StandardAsset.count}"
        @records = StandardAsset.all
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