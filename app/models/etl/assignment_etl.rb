require 'etl'

module Etl
  module AssignmentEtl
    def setup(params)
      Kiba.parse do
        source AssignmentSource, params
        transform AssignmentTransform, params
        destination RecordDestination, model: 'Assignment', action: params[:action]
      end
    end

    module_function :setup
    class AssignmentSource
      def initialize(args)
        section_id = args[:section_id]
        @assignments = ::Assignment.by_section(section_id).includes(:assignable).where(assignable_type: 'Activity')
      end

      def each
        @assignments.each do |assignment|
          yield assignment
        end
      end
    end

    class AssignmentTransform < ExportTransform
      def process(record)
        # merge in fields that assignment needs from related activity
        super(record.attributes.merge('lesson_id' => record.assignable.lesson_id,
                                      'concept_id' => record.assignable.concept_id,
                                      'school_id' => record.section.course.school_id))
      end
    end
  end
end
