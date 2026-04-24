require 'etl'

module Etl
  module SectionEtl
    def setup(params)
      Kiba.parse do
        source SectionSource, params
        transform SectionTransform, params
        destination RecordDestination, model: 'Section', action: params[:action]
      end
    end

    module_function :setup
    class SectionSource
      def initialize(args)
        course_id = args[:course_id]
        @sections = ::Section.by_course(course_id)
      end

      def each
        @sections.each do |section|
          yield section
        end
      end
    end

    class SectionTransform < ExportTransform
      def related_models
        %w[Assignment Enrollment User]
      end

      def process(section)
        params = { 'section_id' => section.id, 'action' => @params[:action] }
        related_models.each do |model_name|
          GbObjectMigratorWorker.perform_async(model_name, params)
        end
        super(section.attributes.merge('school_id' => section.course.school_id))
      end
    end
  end
end
