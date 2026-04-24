require 'etl'

module Etl
  module CategoryEtl
    def setup(params)
      Kiba.parse do
        source CategorySource, params
        transform CategoryTransform, params
        destination RecordDestination, model: 'Category', action: params[:action]
      end
    end

    module_function :setup

    class CategorySource
      def initialize(args)
        course_id = args[:course_id]
        @categories = ::Category.by_course(course_id)
      end

      def each
        @categories.each do |category|
          yield category
        end
      end
    end

    class CategoryTransform < ExportTransform
      def process(category)
        super(category.attributes.merge('school_id' => category.course.school_id))
      end
    end
  end
end
