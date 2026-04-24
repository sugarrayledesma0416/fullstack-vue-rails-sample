require 'etl'

module Etl
  module EnrollmentEtl

    def setup(params)
      Kiba.parse do
        source EnrollmentSource, params
        transform EnrollmentTransform, params
        destination RecordDestination, model: 'Enrollment', action: params[:action]
      end
    end

    module_function :setup

    class EnrollmentSource
      def initialize(args)
        section_id = args[:section_id]
        @enrollments = ::Enrollment.by_section(section_id).where(state: ['enrolled', 're-enrolled', 'marked_complete'])
      end

      def each
        @enrollments.each do |enrollment|
          yield enrollment
        end
      end
    end

    class EnrollmentTransform < ExportTransform
      def process(record)
        # merge in related course's school_id
        super(record.attributes.merge('school_id' => record.section.course.school_id))
      end
    end
  end
end
