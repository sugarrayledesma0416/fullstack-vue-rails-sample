require 'etl'

module Etl
  module ConceptEtl
    def setup(params)
      Kiba.parse do
        source ConceptSource, params
        transform ExportTransform, params
        destination RecordDestination, model: 'Concept', action: params[:action]
      end
    end

    module_function :setup
    class ConceptSource
      def initialize(input)
        start_id = input[:start_id]
        end_id = input[:end_id]
        @concepts = ::Concept.where('id between ? and ?', start_id, end_id)
      end

      def each
        @concepts.each do |concept|
          yield concept
        end
      end
    end
  end
end
