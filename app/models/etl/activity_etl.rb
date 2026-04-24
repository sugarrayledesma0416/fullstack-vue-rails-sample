require 'etl'

module Etl
  module ActivityEtl
    def setup(params)
      Kiba.parse do
        source ActivitySource, params
        transform ExportTransform, params
        destination RecordDestination, model: 'Activity', action: params[:action]
      end
    end
    module_function :setup

    class ActivitySource
      def initialize(args)
        @start_id = args[:start_id]
        @end_id = args[:end_id]
        @activities = ::Activity.where('id between ? and ?', @start_id, @end_id)
      end

      def each
        @activities.each do |activities|
          yield activities
        end
      end
    end
  end
end
