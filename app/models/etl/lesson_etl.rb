require 'etl'

module Etl
  module LessonEtl
    def setup(params)
      Kiba.parse do
        source LessonSource, params
        transform LessonTransform, params
        destination RecordDestination, model: 'Lesson', action: params[:action]
      end
    end

    module_function :setup
    class LessonSource
      def initialize(args)
        start_id = args[:start_id]
        end_id = args[:end_id]
        @lessons = ::Lesson.where('id between ? and ?', start_id, end_id)
      end

      def each
        @lessons.each do |lesson|
          yield lesson
        end
      end
    end

    class LessonTransform < ExportTransform
      def process(record)
        super(record.attributes.merge('unit_rank' => record.unit.rank, 'unit_id' => record.unit.id))
      end
    end
  end
end
