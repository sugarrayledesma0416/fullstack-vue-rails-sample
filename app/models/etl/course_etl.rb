require 'etl'

module Etl
  module CourseEtl
    def setup(params)
      Kiba.parse do
        source CourseSource, params
        transform CourseTransform, params
        destination RecordDestination, model: 'Course', action: params[:action]
      end
    end
    module_function :setup

    class CourseSource
      def initialize(args)
        @start_id = args[:start_id]
        @end_id = args[:end_id]
        @closed_only = args[:closed_only]
        @end_date = args[:end_date]
        @school_ids = args[:school_ids]
      end

      def each
        courses.each do |course|
          yield course
        end
      end

      private def course_range
        if @school_ids.present?
          ::Course.where('school_id IN (?)', @school_ids)
        else
          ::Course.where('id between ? and ?', @start_id, @end_id)
        end
      end

      private def courses
        if @end_date.present?
          month_back = @end_date.to_date - 1.month
          if @closed_only
            course_range.where('end_date < ?', month_back)
          else
            course_range.where('end_date >= ?', month_back)
          end
        else
          course_range
        end
      end
    end

    class CourseTransform < ExportTransform
      def related_models
        %w(Section Category)
      end

      def process(course)
        params = { 'course_id' => course.id, 'action' => @params[:action] }
        related_models.each do |model_name|
          GbObjectMigratorWorker.perform_async(model_name, params)
        end
        current_events_unit_id = course.program.current_events_unit && course.program.current_events_unit.id
        super(course.attributes.merge('current_events_unit_id' => current_events_unit_id))
      end
    end
  end
end
