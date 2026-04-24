module Gradebook
  module Standards
    module ProgressMonitoring
      class SectionReportByAssessmentGroupsPresenter < SectionReportPresenter
        attr_accessor :grouped_activity_ids

        def initialize(section:, program:, **kwargs)
          super

          assessment_type = kwargs[:assessment_type]
          standard_id = kwargs[:standard_id]
          self.grouped_activity_ids = activity_ids_grouped_by_component(
            assessment_type, standard_id, activity_ids
          )
        end

        def component_names
          grouped_activity_ids.keys
        end

        def activity_ids_grouped_by_component(assessment_type, standard_id, activity_ids)
          return unless assessment_type == 'progress_monitoring' &&
                        standard_id.present?

          activities = Activity.where(id: activity_ids).select(:cms_activity_id, :component_name)
          activities.group_by(&:component_name).transform_values do |group|
            group.map(&:cms_activity_id)
          end
        end

        def column_headers(first_column_header)
          {}.tap do |memo|
            memo[first_column_header.to_sym] = first_column_header.titleize
            add_component_headers(memo)
          end
        end

        private def add_component_headers(memo)
          component_names.each do |component_name|
            label = component_name
            cms_activity_ids = grouped_activity_ids[component_name]

            memo[component_name.to_s.to_sym] = {
              category: component_name,
              label:,
              submission_count: submission_count(component_name),
              possible_submissions_count: cms_activity_ids.length * student_count
            }
          end
        end

        def submission_count(component_name)
          cms_activity_ids = grouped_activity_ids[component_name]
          StandardsResults.count_by_activities_and_section(cms_activity_ids, section)
        end
      end
    end
  end
end
